# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

PROMPT="%F{green}%n@%m %1~ $ %f%F{yellow}"
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
preexec () { echo -ne "\e[0m" }

source /usr/local/share/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# John the ripper command path
export PATH="/usr/local/Cellar/john-jumbo/1.9.0_1/share/john/:$PATH"

export PATH="/usr/local/mysql/bin:$PATH"
export PATH="/Applications/IntelliJ IDEA CE.app/Contents/MacOS:$PATH"
export PATH="/Library/Frameworks/Python.framework/Versions/3.12/bin:$PATH"

# Change grep to always show color
export GREP_OPTIONS='--color=auto'

export PATH="/usr/local/opt/openjdk/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"


# Quick-cd script, to quickly search and change to the desired directory, simply run in terminal:
# qcd Optional-parents/my-dir-name Optional-excluded-directory
# quick-cd.py is at /Users/mac/Desktop/repos/python-scripts/quick-cd.py
function qcd() {
    cd /Users/mac/Desktop/repos/python-scripts
    result=$(python3 quick-cd.py "$@" | tee /dev/tty | sed -n -e '/^$/!h' -e '$x;$p') # Assign output to var, print it on screen, remove prompt
    if [[ -n $result ]]; then  # Check if result is not empty
        cd $result  # Use the output to change directory
    else
        cd - > /dev/null # Change to the original directory, prevent printing to terminal
        echo "No directory found"
    fi
}

# script for seperate lines copy paste
# Initialize arrays to store paths of files to copy and move
M_COPY_FILES=()
M_MOVE_FILES=()

# Function to mark files for copying
function mcp {
    for file in "$@"; do
        if [ -e "$file" ]; then
            M_COPY_FILES+=("$(realpath "$file")")
            echo "Marked $file for copying"
        else
            echo "File $file does not exist"
        fi
    done
}

# Function to mark files for moving
function mmv {
    for file in "$@"; do
        if [ -e "$file" ]; then
            M_MOVE_FILES+=("$(realpath "$file")")
            echo "Marked $file for moving"
        else
            echo "File $file does not exist"
        fi
    done
}

# Function to paste the marked files to the specified directories (or current directory if not specified)
function mp {
    local dest_dirs=("$@")  # Get all specified directories

    # Default to current directory if no directories are provided
    if [ ${#dest_dirs[@]} -eq 0 ]; then
        dest_dirs=(".")
    fi

    # Check if each destination directory exists
    for dest_dir in "${dest_dirs[@]}"; do
        if [ ! -d "$dest_dir" ]; then
            echo "Destination directory $dest_dir does not exist"
            return 1
        fi
    done

    # Move files to each specified directory
    if [ ${#M_MOVE_FILES[@]} -gt 0 ]; then
        for file in "${M_MOVE_FILES[@]}"; do
            for dest_dir in "${dest_dirs[@]}"; do
                mv "$file" "$dest_dir"
                echo "Moved $file to $dest_dir"
            done
        done
        # Clear the array after moving files
        M_MOVE_FILES=()
    elif [ ${#M_COPY_FILES[@]} -gt 0 ]; then
        # Copy files to each specified directory
        for file in "${M_COPY_FILES[@]}"; do
            for dest_dir in "${dest_dirs[@]}"; do
                cp -r "$file" "$dest_dir"
                echo "Copied $file to $dest_dir"
            done
        done
        # Clear the array after copying files
        M_COPY_FILES=()
    else
        echo "No file marked for copying or moving"
    fi
}

# mark reset to reest the marked files
function mr {
    M_COPY_FILES=()
    M_MOVE_FILES=()
    echo "Reset marked files"
}
# marked list to list the marked files
function ml {
    if [ ${#M_MOVE_FILES[@]} -gt 0 ]; then
        echo "Files marked for moving:"
        for file in "${M_MOVE_FILES[@]}"; do
            echo "$file"
        done
    elif [ ${#M_COPY_FILES[@]} -gt 0 ]; then
        echo "Files marked for copying:"
        for file in "${M_COPY_FILES[@]}"; do
            echo "$file"
        done
    else
        echo "No file marked for copying or moving"
    fi
}

# auto pair plugin
source $HOMEBREW_PREFIX/share/zsh-autopair/autopair.zsh

# Alias
# bin instead of rm
alias bi='trash'
# look inside trash
alias bil='lsd -ltr --group-dirs=first --date=relative --blocks=date,name ~/.Trash'
# enhanced ls
alias ls='lsd -ltr --group-dirs=first --date=relative --blocks=size,date,name'
alias lsa='lsd -a -ltr --group-dirs=first --date=relative --blocks=size,date,name'
# weather
alias weather='curl -s "wttr.in?n1"'
alias forecast='curl -s "wttr.in?n2"'
#nethack 
alias nethack='ssh -o SetEnv="DGLAUTH=cyclone1070:h0angmai" nethack@au.hardfought.org'
# wiki
alias wiki='wiki -w 80'
# quicklook
alias ql='qlmanage -p'
# neovide
alias vide='neovide --fork'
# mongo
alias mstart='brew services start mongodb-community@8.0'
alias mstop='brew services stop mongodb-community@8.0'
# fuzzy cd
source /usr/local/bin/fuzzycd
# gemini cli
export GEMINI_API_KEY="AIzaSyCqOVNc1gQchw-WrOVEK6WoJBkALYNTPDE"
alias geminif="gemini -m gemini-2.5-flash"

# Custom tmux function for intelligent session handling
t() {
  # This is the old "Priority 0" logic for when 't' is run alone.
  if [[ -z "$1" ]]; then
    if [[ -n "$TMUX" ]]; then
        command tmux choose-tree -s
    else
        # Try to attach, if it fails (exit code != 0), start a new session.
        command tmux attach-session || command tmux new-session
    fi
    return $?
  fi

  # This is the "Priority 3" logic, copied verbatim.
  local session_name="$1"
  if command tmux has-session -t "$session_name" 2>/dev/null; then
    # SESSION EXISTS: Attach or switch to it.
    if [[ -n "$TMUX" ]]; then
      command tmux switch-client -t "$session_name"
    else
      command tmux attach-session -t "$session_name"
    fi
  else
    # SESSION DOES NOT EXIST: Create a new session with that name.
    if [[ -n "$TMUX" ]]; then
      command tmux new-session -d -s "$session_name" "${@:2}" && command tmux switch-client -t "$session_name"
    else
      command tmux new-session -s "$session_name" "${@:2}"
    fi
  fi
}

# --- Dedicated functions for specific actions ---
# The logic from the old "Priority 1" block is moved here.

# Attach to a session (or show chooser).
# Logic from 'if [[ "$1" == "a" ]]'
ta() {
  if [[ -n "$TMUX" ]]; then
    if [[ -n "$1" ]]; then
      command tmux switch-client -t "$1"
    else
      command tmux choose-tree -s
    fi
  else
    if [[ -n "$1" ]]; then
      command tmux attach-session -t "$1"
    else
      command tmux attach-session
    fi
  fi
}

# Detach from a session (with smart fallback to 'default').
# Logic from 'if [[ "$1" == "d" ]]'
td() {
  if [[ -n "$TMUX" ]]; then
    command tmux detach-client -E 'tmux attach-session -t default'
  else
    command tmux detach-client
  fi
}

# Create one or more new sessions.
tn() {
  # If no arguments, show usage and exit.
  if [[ $# -eq 0 ]]; then
    echo "Usage: tn <session-name-1> [session-name-2] ..."
    return 1
  fi

  local last_session_name
  # Loop through every argument provided.
  for session_name in "$@"; do
    # Try to create a new session in the background.
    if command tmux new-session -d -s "$session_name" 2>/dev/null; then
      echo "Created session: '$session_name'"
      # Keep track of the last one we successfully created.
      last_session_name="$session_name"
    else
      # Report if it fails (likely because it already exists).
      echo "Skipping session '$session_name': session already exists."
    fi
  done

  # If we are inside tmux and at least one session was created,
  # switch to the LAST one in the list.
  if [[ -n "$TMUX" && -n "$last_session_name" ]]; then
    command tmux switch-client -t "$last_session_name"
  # If we are OUTSIDE tmux and at least one session was created,
  # attach to the FIRST one that was listed.
  elif [[ -z "$TMUX" && -n "$last_session_name" ]]; then
    command tmux attach-session -t "$1"
  fi
}

# Kill one or more sessions. This function is designed to be called via
# the 'noglob tk' alias to allow for glob patterns.
tk-underlying-function() {
  # If no arguments, handle smart-kill for the current session.
  if [[ $# -eq 0 ]]; then
    local current_session_no_args
    [[ -n "$TMUX" ]] && current_session_no_args=$(command tmux display-message -p '#S')
    if [[ "$current_session_no_args" != "default" && $(command tmux has-session -t default 2>/dev/null) ]]; then
      command tmux run-shell "tmux switch-client -t default && tmux kill-session -t '$current_session_no_args'" &
    else
      command tmux kill-session
    fi
    return $?
  fi

  # --- Implementing the "Lifeboat" Strategy (Silent) ---
  
  local -a all_sessions sessions_to_kill unique_sessions
  all_sessions=( ${(f)"$(command tmux list-sessions -F '#{session_name}')"} )

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
    # Silently exit if no sessions match.
    return 1
  fi
  
  unique_sessions=( ${(u)sessions_to_kill} )
  
  local current_session
  [[ -n "$TMUX" ]] && current_session=$(command tmux display-message -p '#S')

  # --- Decision logic based on your new rules ---

  # Check if 'default' is on the kill list OR if the current session is targeted.
  if [[ " ${unique_sessions[@]} " =~ " default " || " ${unique_sessions[@]} " =~ " $current_session " ]]; then
    local lifeboat_session="temp-lifeboat-$(date +%s)"
    
    local cmd_sequence="tmux new-session -d -s '$lifeboat_session' ; "
    cmd_sequence+="tmux switch-client -t '$lifeboat_session' ; "
    
    for target in "${unique_sessions[@]}"; do
      cmd_sequence+="tmux kill-session -t '$target' ; "
    done
    
    cmd_sequence+="tmux new-session -d -s default ; "
    cmd_sequence+="tmux switch-client -t default ; "
    cmd_sequence+="tmux kill-session -t '$lifeboat_session'"
    
    command tmux run-shell "sleep 0.1; $cmd_sequence" &
    
  # Simple case: we are not killing 'default' or the current session.
  else
    for target in "${unique_sessions[@]}"; do
      command tmux kill-session -t "$target"
    done
  fi
}
# This alias is required to prevent the 'zsh: no matches found' error.
# It must be placed AFTER the function definition.
alias tk='noglob tk-underlying-function'

alias tls='command tmux list-sessions -F "#{session_name}:#{session_created}:#{session_attached}" | awk -F: '\''{
    cmd = "date -r " $2 " +\"%a %b %d %T %Y\"";
    cmd | getline fdate;
    close(cmd);
    attached = ($3 == "1") ? " (attached)" : "";
    printf "%s: created %s%s\n", $1, fdate, attached;
}'\'''
alias tka='command tmux kill-server'
