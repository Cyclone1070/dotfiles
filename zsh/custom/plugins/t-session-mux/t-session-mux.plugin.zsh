# force UTF-8 mode for tmux
alias tmux='tmux -u'
# --- Helper function to ensure a 'default' session exists ---
# This is used by creation and detach commands to guarantee a fallback.
_ensure_default_session_exists() {
  if ! command tmux -u has-session -t default 2>/dev/null; then
    command tmux -u new-session -d -s default
  fi
}

# Smartly attach/switch to the first parameter (with partial match),
# then create new sessions for all subsequent parameters.
# If the first parameter doesn't match any existing session,
# it creates all specified sessions and attaches to the first one.
t() {
  # If 't' is run alone, use the original "chooser" logic.
  if [[ -z "$1" ]]; then
    if [[ -n "$TMUX" ]]; then
        command tmux -u choose-tree -s
    else
        _ensure_default_session_exists
        command tmux -u attach-session || command tmux -u new-session -s default
    fi
    return $?
  fi

  local query="$1"
  # Find the first session that partially matches the query.
  local target_session=$(command tmux -u list-sessions -F '#S' 2>/dev/null | command grep --color=never "$query" | command head -n 1)

  # CASE 1: A matching session was found.
  if [[ -n "$target_session" ]]; then
    if [[ $# -gt 1 ]]; then
      for other_session_name in "${@:2}"; do
        command tmux -u new-session -d -s "$other_session_name" 2>/dev/null
      done
      # NEW: Ensure 'default' exists if we performed a create operation.
      _ensure_default_session_exists
    fi

    if [[ -n "$TMUX" ]]; then
      command tmux -u switch-client -t "$target_session"
    else
      command tmux -u attach-session -t "$target_session"
    fi

  # CASE 2: No matching session was found.
  else
    for session_name in "$@"; do
      command tmux -u new-session -d -s "$session_name" 2>/dev/null
    done
    # NEW: Ensure 'default' exists since we performed a create operation.
    _ensure_default_session_exists

    if [[ -n "$TMUX" ]]; then
      command tmux -u switch-client -t "$1"
    else
      command tmux -u attach-session -t "$1"
    fi
  fi
}

# Attach to a session (or show chooser).
ta() {
  if [[ -n "$TMUX" ]]; then
    if [[ -n "$1" ]]; then
      command tmux -u switch-client -t "$1"
    else
      command tmux -u choose-tree -s
    fi
  else
    if [[ -n "$1" ]]; then
      command tmux -u attach-session -t "$1"
    else
      _ensure_default_session_exists
      command tmux -u attach-session
    fi
  fi
}

# Detach from a session, or switch to 'default' if inside tmux.
td() {
  # If inside a tmux session...
  if [[ -n "$TMUX" ]]; then
    # Ensure the 'default' session exists so we can switch to it.
    _ensure_default_session_exists
    # Directly switch to the 'default' session. No flicker.
    command tmux -u switch-client -t default
  else
    # If outside tmux, perform a standard detach.
    command tmux -u detach-client
  fi
}

# Create one or more new sessions.
tn() {
  if [[ $# -eq 0 ]]; then
    return 1
  fi

  for session_name in "$@"; do
    command tmux -u new-session -d -s "$session_name" 2>/dev/null
  done
  # NEW: Ensure 'default' exists since this is a create operation.
  _ensure_default_session_exists

  if [[ -n "$TMUX" ]]; then
    command tmux -u switch-client -t "$1"
  else
    command tmux -u attach-session -t "$1"
  fi
}

# Kill one or more sessions. This function is designed to be called via
# the 'noglob tk' alias to allow for glob patterns.
tk-underlying-function() {
  # --- MODIFIED: Corrected logic for 'tk' with no arguments ---
  if [[ $# -eq 0 ]]; then
    # This command should only work if we are inside tmux.
    if [[ -z "$TMUX" ]]; then
      return 1
    fi

    local current_session_no_args
    current_session_no_args=$(command tmux -u display-message -p '#S')

    # If we are already in the 'default' session, do nothing.
    if [[ "$current_session_no_args" == "default" ]]; then
      return 0
    fi

    # For any other session, ensure 'default' exists and then run the detached switch-and-kill.
    _ensure_default_session_exists
    local cmd_sequence="tmux -u switch-client -t default && tmux -u kill-session -t '$current_session_no_args'"
    command tmux -u run-shell "sleep 0.1; $cmd_sequence" &
    
    return $?
  fi

  # --- The rest of the "lifeboat" logic for 'tk <pattern>' remains the same ---
  
  local -a all_sessions sessions_to_kill unique_sessions
  all_sessions=( ${(f)"$(command tmux -u list-sessions -F '#{session_name}')"} )

  for pattern in "$@"; do
    local regex_pattern="^${pattern//\*/.*}$"
    regex_pattern="${regex_pattern//\?/.}"
    for session in "${all_sessions[@]}"; do
      if [[ $session =~ $regex_pattern ]]; then
        sessions_to_kill+=("$session")
      fi
    done
  done

  if [[ ${#sessions_to_kill[@]} -eq 0 ]]; then
    return 1
  fi
  
  unique_sessions=( ${(u)sessions_to_kill} )
  
  local current_session
  [[ -n "$TMUX" ]] && current_session=$(command tmux -u display-message -p '#S')

  # Special case for ONLY killing 'default' to reload it without switching.
  if [[ ${#unique_sessions[@]} -eq 1 && "${unique_sessions[1]}" == "default" ]]; then
    command tmux -u kill-session -t default &>/dev/null
    command tmux -u new-session -d -s default
    return $?
  fi

  # Check if 'default' or the current session is targeted to trigger the lifeboat.
  if [[ " ${unique_sessions[@]} " =~ " default " || " ${unique_sessions[@]} " =~ " $current_session " ]]; then
    local lifeboat_session="temp-lifeboat-$(date +%s)"
    
    local cmd_sequence="tmux -u new-session -d -s '$lifeboat_session' ; "
    cmd_sequence+="tmux -u switch-client -t '$lifeboat_session' ; "
    
    for target in "${unique_sessions[@]}"; do
      cmd_sequence+="tmux -u kill-session -t '$target' ; "
    done
    
    cmd_sequence+="tmux -u new-session -d -s default ; "
    cmd_sequence+="tmux -u switch-client -t default ; "
    cmd_sequence+="tmux -u kill-session -t '$lifeboat_session'"
    
    command tmux -u run-shell "sleep 0.1; $cmd_sequence" &
    
  # Simple case: we are not killing 'default' or the current session.
  else
    for target in "${unique_sessions[@]}"; do
      command tmux -u kill-session -t "$target"
    done
  fi
}
# This alias is required to prevent the 'zsh: no matches found' error.
# It must be placed AFTER the function definition.
alias tk='noglob tk-underlying-function'

alias tls='command tmux -u list-sessions -F "#{session_name}:#{session_created}:#{session_attached}" | awk -F: '\''{
    cmd = "date -r " $2 " +\"%a %b %d %T %Y\"";
    cmd | getline fdate;
    close(cmd);
    attached = ($3 == "1") ? " (attached)" : "";
    printf "%s: created %s%s\n", $1, fdate, attached;
}'\'''
alias tka='command tmux -u kill-server'