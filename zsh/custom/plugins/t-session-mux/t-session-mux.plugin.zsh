# force UTF-8 mode for tmux
alias tmux='tmux -u'
# --- Helper function to ensure a 'default' window exists at index 0 ---
# This is used by creation and detach commands to guarantee a fallback and enforce index 0 for default.
_ensure_default_window_exists() {
  local default_window_name="default"
  local default_window_index=0
  local window_name_at_index_0=""

  # Get the name of the window at index 0, if it exists
  if command tmux -u has-window -t :"$default_window_index" 2>/dev/null; then
    window_name_at_index_0=$(command tmux -u display-message -p '#{window_name}' -t :"$default_window_index" 2>/dev/null)
  fi

  if [[ "$window_name_at_index_0" == "$default_window_name" ]]; then
    # Case 1: Window at index 0 exists and is already named "default". Do nothing.
    return 0
  elif [[ -n "$window_name_at_index_0" ]]; then
    # Case 2: Window exists at index 0, but it's not named "default". Rename it.
    command tmux -u rename-window -t :"$default_window_index" "$default_window_name" 2>/dev/null
    echo "Renamed window at index $default_window_index to '$default_window_name'." >&2
  else
    # Case 3: No window exists at index 0. Create the default window there.
    command tmux -u new-window -d -t :"$default_window_index" -n "$default_window_name" 2>/dev/null
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
  _ensure_default_window_exists # Ensure default window exists at index 0
  # If 't' is run alone, use the window switcher
  if [[ -z "$1" ]]; then
    if [[ -n "$TMUX" ]]; then
        command tmux -u choose-window
    else
		command tmux -u attach-session || command tmux -u new-session -s default -n default
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

    if [[ -n "$TMUX" ]]; then
      command tmux -u select-window -t :"$1"
    else
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
      command tmux -u attach-session || command tmux -u new-session -s default -n default
      command tmux -u select-window -t :"$1"
    else
      _ensure_default_window_exists
      command tmux -u attach-session || command tmux -u new-session -s default -n default
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
  _ensure_default_window_exists # Ensure default window exists at index 0
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
    command tmux -u attach-session || command tmux -u new-session -s default -n default
    command tmux -u select-window -t :"$1"
  fi
}

# Kill one or more windows.
# Kill the current pane (no args) or specified windows (with args).
tk-underlying-function() {
  # --- MODIFIED BLOCK: Logic for 'tk' with no arguments ---
  if [[ $# -eq 0 ]]; then
    # This command should only work if we are inside tmux.
    if [[ -z "$TMUX" ]]; then
      echo "Error: Cannot kill pane outside of a tmux session." >&2
      return 1
    fi

    # The 'kill-pane' command is smart:
    # - If there are multiple panes, it closes the current one.
    # - If it's the last pane, it closes the window as well.
    command tmux kill-pane
    command tmux display-message "Pane killed"
    return $?
  fi
  # --- END OF MODIFIED BLOCK ---


  # --- UNCHANGED: The rest of the logic for 'tk <pattern>' ---
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

# Helper function to handle the logic for splitting and joining.
# Not intended to be called directly by the user.
_t_split_and_join() {
  local split_flag="$1" # The flag for tmux command (-v or -h)
  local query="$2"      # The user's search pattern

  # Guard clause: Must be inside a tmux session.
  if [[ -z "$TMUX" ]]; then
    echo "Error: This command can only be run inside a tmux session." >&2
    return 1
  fi

  # If no search query was provided, perform a simple split.
  if [[ -z "$query" ]]; then
    command tmux split-window "$split_flag"
    return $?
  fi

  # Find all matching windows
  local matches=$(command tmux list-windows -F '#W' 2>/dev/null | grep --color=never -i "$query")
  local target_window=""

  # Check how many matches were found.
  if [[ -z "$matches" ]]; then
    echo "Error: No window found matching '$query'." >&2
    return 1
  # The '-n' flag checks if there is more than one line of output.
  elif [[ -n "$(echo "$matches" | tail -n +2)" ]]; then
    # --- NEW: Floating FZF Logic ---
    # Create a temporary file to capture fzf's output.
    local tmp_file
    tmp_file=$(mktemp) || return 1 # Exit if mktemp fails

    # Use a trap to ensure the temp file is deleted when the function exits.
    # 'RETURN' is a Zsh-specific trap that is better for functions than 'EXIT'.
    trap "rm -f '$tmp_file'" RETURN

    # Run fzf inside a styled tmux popup, redirecting the selection to the temp file.
    command tmux display-popup -w 80% -h 60% -b rounded -E "echo \"$matches\" | fzf > \"$tmp_file\""

    # Read the selection back from the temp file.
    target_window=$(cat "$tmp_file")

    # If the user cancelled fzf (e.g., pressed Esc), the file will be empty. Abort.
    if [[ -z "$target_window" ]]; then
      return 1
    fi
    # --- END OF NEW LOGIC ---
  else
    # Exactly one match was found.
    target_window="$matches"
  fi

  local current_window=$(command tmux display-message -p '#W')
  if [[ "$current_window" == "$target_window" ]]; then
    echo "Error: Cannot join a window with itself." >&2
    return 1
  fi

  # "Default" Window Safety Net
  local joining_default=false
  if [[ "$target_window" == "default" ]]; then
    joining_default=true
  fi

  # Use join-pane, which both splits and moves the source pane.
  command tmux join-pane "$split_flag" -s ":$target_window"

  # Recreate 'default' if it was just joined
  if [[ "$joining_default" == true ]]; then
    command tmux new-window -d -t :0 -n "default"
    command tmux display-message "Joined 'default' and recreated it at index 0"
  fi
}
# Split pane vertically. If a pattern is given, join the matched window.
# Usage: tv [window_name_pattern]
tv() {
  # The '-v' flag specifies a vertical split.
  # We pass all arguments ("$@") to the helper.
  _t_split_and_join "-v" "$@"
}

# Split pane horizontally. If a pattern is given, join the matched window.
# Usage: th [window_name_pattern]
th() {
  # The '-h' flag specifies a horizontal split.
  # We pass all arguments ("$@") to the helper.
  _t_split_and_join "-h" "$@"
}

# Unsplit the current pane into a new, named window.
# A name for the new window is required.
# Usage: tu <new_window_name>
tu() {
  # Guard clause: Must be inside a tmux session.
  if [[ -z "$TMUX" ]]; then
    echo "Error: This command can only be run inside a tmux session." >&2
    return 1
  fi

  local new_name="$1"

  # --- MODIFIED LOGIC ---
  # Check if a name was provided. If not, print usage and exit.
  if [[ -z "$new_name" ]]; then
    echo "Usage: tu <new_window_name>" >&2
    echo "Error: You must provide a name for the new window." >&2
    return 1
  fi

  # Check for uniqueness using the existing helper function.
  if ! _t_check_unique_window_name "$new_name"; then
    # The helper function already prints a detailed error message.
    return 1
  fi

  # The 'break-pane' command creates the new window and switches to it.
  # We chain the 'rename-window' command right after it.
  command tmux break-pane \; rename-window "$new_name"
}
