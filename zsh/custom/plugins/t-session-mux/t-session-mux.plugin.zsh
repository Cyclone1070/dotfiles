# force UTF-8 mode for tmux
alias tmux='tmux -u'
# --- Helper function to ensure a 'default' window exists ---
# This is used by creation and detach commands to guarantee a fallback.
_ensure_default_window_exists() {
  # Check if a window named 'default' exists in the current session
  if ! command tmux -u has-window -t :default 2>/dev/null; then
    # If not, create a new window named 'default' at index 0
    command tmux -u new-window -d -t :0 -n default 2>/dev/null
  fi
  # Ensure there's always at least one window. If the default was the only one and got killed,
  # this will recreate it.
  if [[ $(command tmux -u list-windows -F '#{window_name}' 2>/dev/null | wc -l) -eq 0 ]]; then
    command tmux -u new-window -d -t :0 -n default 2>/dev/null
  fi
}

# If the first parameter doesn't match any existing session,
# it creates all specified sessions and attaches to the first one.
# Smartly attach/switch to the first parameter (with partial match),
# then create new windows for all subsequent parameters.
# If the first parameter doesn't match any existing window,
# it creates all specified windows and attaches to the first one.
t() {
  # If 't' is run alone, use the window switcher
  if [[ -z "$1" ]]; then
    if [[ -n "$TMUX" ]]; then
        command tmux -u choose-window
    else
        _ensure_default_window_exists
        command tmux -u attach-session || command tmux -u new-session -s default
    fi
    return $?
  fi

  local query="$1"
  # Check if the query is a number (window index)
  if [[ "$query" =~ ^[0-9]+$ ]]; then
    if [[ -n "$TMUX" ]]; then
      command tmux -u select-window -t :"$query" 2>/dev/null
      if [[ $? -eq 0 ]]; then
        return 0
      else
        # If window index doesn't exist, try to create a new window with that name
        # (though this is less common for numeric inputs)
        local window_name="$query"
        if ! command tmux -u has-window -t :"$window_name" 2>/dev/null; then
          command tmux -u new-window -d -n "$window_name" 2>/dev/null
          command tmux -u select-window -t :"$window_name"
        fi
        return $?
      fi
    else
      _ensure_default_window_exists
      command tmux -u attach-session || command tmux -u new-session -s default
      command tmux -u select-window -t :"$query" 2>/dev/null
      return $?
    fi
  fi

  # Find the first window that partially matches the query.
  local target_window=$(command tmux -u list-windows -F '#W' 2>/dev/null | command grep --color=never "$query" | command head -n 1)

  # CASE 1: A matching window was found.
  if [[ -n "$target_window" ]]; then
    if [[ $# -gt 1 ]]; then
      for other_window_name in "${@:2}"; do
        if ! command tmux -u has-window -t :"$other_window_name" 2>/dev/null; then
          command tmux -u new-window -d -n "$other_window_name" 2>/dev/null
        fi
      done
      _ensure_default_window_exists
    fi

    if [[ -n "$TMUX" ]]; then
      command tmux -u select-window -t :"$target_window"
    else
      command tmux -u attach-session || command tmux -u new-session -s default
      command tmux -u select-window -t :"$target_window"
    fi

  # CASE 2: No matching window was found.
  else
    for window_name in "$@"; do
      if ! command tmux -u has-window -t :"$window_name" 2>/dev/null; then
        command tmux -u new-window -d -n "$window_name" 2>/dev/null
      fi
    done
    _ensure_default_window_exists

    if [[ -n "$TMUX" ]]; then
      command tmux -u select-window -t :"$1"
    else
      _ensure_default_window_exists
      command tmux -u attach-session || command tmux -u new-session -s default
      command tmux -u select-window -t :"$1"
    fi
  fi
}

# Attach to a window (or show chooser).
ta() {
  if [[ -n "$TMUX" ]]; then
    if [[ -n "$1" ]]; then
      command tmux -u select-window -t :"$1"
    else
      command tmux -u choose-window
    fi
  else
    if [[ -n "$1" ]]; then
      _ensure_default_window_exists
      command tmux -u attach-session || command tmux -u new-session -s default
      command tmux -u select-window -t :"$1"
    else
      _ensure_default_window_exists
      command tmux -u attach-session || command tmux -u new-session -s default
    fi
  fi
}

# Detach from a client, or switch to 'default' window if inside tmux.
td() {
  # If inside a tmux session...
  if [[ -n "$TMUX" ]]; then
    # Ensure the 'default' window exists so we can switch to it.
    _ensure_default_window_exists
    # Directly switch to the 'default' window. No flicker.
    command tmux -u select-window -t :default
  else
    # If outside tmux, perform a standard detach.
    command tmux -u detach-client
  fi
}

# Create one or more new windows.
tn() {
  if [[ $# -eq 0 ]]; then
    return 1
  fi

  for window_name in "$@"; do
    if ! command tmux -u has-window -t :"$window_name" 2>/dev/null; then
      command tmux -u new-window -d -n "$window_name" 2>/dev/null
    fi
  done
  _ensure_default_window_exists

  if [[ -n "$TMUX" ]]; then
    command tmux -u select-window -t :"$1"
  else
    _ensure_default_window_exists
    command tmux -u attach-session || command tmux -u new-session -s default
    command tmux -u select-window -t :"$1"
  fi
}

# Kill one or more windows.
tk-underlying-function() {
  # --- MODIFIED: Logic for 'tk' with no arguments ---
  if [[ $# -eq 0 ]]; then
    # This command should only work if we are inside tmux.
    if [[ -z "$TMUX" ]]; then
      return 1
    fi

    local current_window_name
    current_window_name=$(command tmux -u display-message -p '#W')
    local current_window_index=$(command tmux -u display-message -p '#I')

    # If we are in the 'default' window, kill it and create a new one at index 0.
    if [[ "$current_window_name" == "default" ]]; then
      command tmux -u kill-window -t :"$current_window_index" 2>/dev/null
      _ensure_default_window_exists # Recreate default at index 0
      command tmux -u select-window -t :0 # Switch to the new default
    else
      # For any other window, kill it and switch to 'default'.
      command tmux -u kill-window -t :"$current_window_index" 2>/dev/null
      _ensure_default_window_exists # Ensure default exists
      command tmux -u select-window -t :default # Switch to default
    fi
    return $?
  fi

  # --- The rest of the logic for 'tk <pattern>' ---
  local -a all_windows windows_to_kill unique_windows
  all_windows=( ${(f)"$(command tmux -u list-windows -F '#{window_name}')"} )

  for pattern in "$@"; do
    local regex_pattern="^${pattern//\*/.*}$"
    regex_pattern="${regex_pattern//\?/.}"
    for window in "${all_windows[@]}"; do
      if [[ $window =~ $regex_pattern ]]; then
        windows_to_kill+=("$window")
      fi
    done
  done

  if [[ ${#windows_to_kill[@]} -eq 0 ]]; then
    return 1
  fi
  
  unique_windows=( ${(u)windows_to_kill} )
  
  local current_window
  [[ -n "$TMUX" ]] && current_window=$(command tmux -u display-message -p '#W')

  # Check if 'default' or the current window is targeted.
  if [[ " ${unique_windows[@]} " =~ " default " || " ${unique_windows[@]} " =~ " $current_window " ]]; then
    # If the current window or default is being killed, ensure we switch away first.
    _ensure_default_window_exists
    command tmux -u select-window -t :default
    sleep 0.1 # Give tmux a moment to switch
  fi

  for target in "${unique_windows[@]}"; do
    command tmux -u kill-window -t :"$target" 2>/dev/null
  done
  _ensure_default_window_exists # Ensure default is still there after killing
}
# This alias is required to prevent the 'zsh: no matches found' error.
# It must be placed AFTER the function definition.
alias tk='noglob tk-underlying-function'

alias tls='command tmux -u list-windows -F "#{window_name}:#{window_index}:#{window_active}" | awk -F: "'\''{ active = ($3 == "1") ? " (active)" : ""; printf "%s:%s%s\n", $1, $2, active; }'\'''
alias tka='command tmux -u kill-server'
