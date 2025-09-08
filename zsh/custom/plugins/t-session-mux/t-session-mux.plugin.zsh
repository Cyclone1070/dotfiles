# force UTF-8 mode for tmux
alias tmux='tmux -u'
# --- Helper function to ensure a 'default' window exists at index 0 ---
# This is used by creation and detach commands to guarantee a fallback and enforce index 0 for default.
_ensure_default_window_exists() {
  local default_window_name="default"
  local default_window_index=0

  # Check if window at index 0 exists
  if command tmux -u has-window -t :"$default_window_index" 2>/dev/null; then
    local current_window_at_index_0=$(command tmux -u display-message -p '#{window_name}' -t :"$default_window_index" 2>/dev/null)
    if [[ "$current_window_at_index_0" != "$default_window_name" ]]; then
      # If window 0 exists but is not named 'default', rename it to 'default'
      command tmux -u rename-window -t :"$default_window_index" "$default_window_name" 2>/dev/null
      echo "Renamed window at index $default_window_index to '$default_window_name'." >&2
    fi
  else
    # If window at index 0 does not exist, create 'default' at index 0
    command tmux -u new-window -d -t :"$default_window_index" -n "$default_window_name" 2>/dev/null
    echo "Created default window at index $default_window_index." >&2
  fi

  # Ensure there's always at least one window. This handles cases where all windows might have been killed.
  if [[ $(command tmux -u list-windows -F '#{window_name}' 2>/dev/null | wc -l) -eq 0 ]]; then
    command tmux -u new-window -d -t :"$default_window_index" -n "$default_window_name" 2>/dev/null
    echo "Recreated default window as no windows were found." >&2
  fi
}

# --- Helper function to check for unique window names ---
_t_check_unique_window_name() {
  local new_name="$1"
  if command tmux -u list-windows -F '#{window_name}' 2>/dev/null | grep -q -E "^${new_name}$"; then
    echo "Error: A window named '$new_name' already exists. Please choose a unique name." >&2
    return 1
  fi
  return 0
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
        return 1 # Indicate failure to select non-existent window
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
        if _t_check_unique_window_name "$other_window_name"; then
          if ! command tmux -u has-window -t :"$other_window_name" 2>/dev/null; then
            command tmux -u new-window -d -n "$other_window_name" 2>/dev/null
          fi
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
      if _t_check_unique_window_name "$window_name"; then
        if ! command tmux -u has-window -t :"$window_name" 2>/dev/null; then
          command tmux -u new-window -d -n "$window_name" 2>/dev/null
        fi
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
    if _t_check_unique_window_name "$window_name"; then
      if ! command tmux -u has-window -t :"$window_name" 2>/dev/null; then
        command tmux -u new-window -d -n "$window_name" 2>/dev/null
      fi
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

    # If we are in the 'default' window, kill it safely by offloading the task.
    if [[ "$current_window_name" == "default" ]]; then
      local temp_window_name="defaultkilltemp"
      local default_window_index=0
      local default_window_name="default"

      # Create a temporary window in detached mode
      command tmux -u new-window -d -n "$temp_window_name" 2>/dev/null

      # Send commands to the temporary window to execute the sequence
      command tmux -u send-keys -t "$temp_window_name" "
        tmux kill-window -t :$current_window_index;
        tmux new-window -d -t :$default_window_index -n $default_window_name;
        tmux select-window -t :$default_window_index;
        tmux kill-window -t :$temp_window_name;
        exit
      " C-m

      sleep 0.1 # Give tmux a moment to process the commands
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

_t_list_windows() {
  if [[ -n "$TMUX" ]]; then
    command tmux -u list-windows -F '#{window_index}: #{window_name}#{?window_active, (active),}'
  else
    echo "Not in a tmux session." >&2
  fi
}
alias tls='_t_list_windows'
alias tka='command tmux -u kill-server'
