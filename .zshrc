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
# Prioritizes valid commands, then falls back to "attach-or-create".
t() {
  # --- Priority 0: No arguments ---
  # If `tmux` is run alone, attach to the last session or create a new one.
  if [[ -z "$1" ]]; then
    if [[ -n "$TMUX" ]]; then
        command tmux choose-tree -s
    else
        # Try to attach, if it fails (exit code != 0), start a new session.
        command tmux attach-session || command tmux new-session
    fi
    return $?
  fi

  # --- Priority 1: Custom Aliases ---
  # These are your special, hardcoded shortcuts.

  # 'tmux d'
  if [[ "$1" == "d" && -z "$2" ]]; then
    if [[ -n "$TMUX" ]]; then
      command tmux detach-client -E 'tmux attach-session -t default'
    else
      command tmux detach-client
    fi
    return $?
  fi

  # 'tmux n "name"'
  if [[ "$1" == "n" && -n "$2" ]]; then
    if [[ -n "$TMUX" ]]; then
      command tmux new-session -d -s "$2" "${@:3}" && command tmux switch-client -t "$2"
    else
      command tmux new-session -s "$2" "${@:3}"
    fi
    return $?
  fi

  # 'tmux a "name"'
  if [[ "$1" == "a" ]]; then
    if [[ -n "$TMUX" ]]; then
      if [[ -n "$2" ]]; then
        command tmux switch-client -t "$2"
      else
        command tmux choose-tree -s
      fi
    else
      if [[ -n "$2" ]]; then
        command tmux attach-session -t "$2"
      else
        command tmux attach-session
      fi
    fi
    return $?
  fi

  # 'tmux k "name"'
  if [[ "$1" == "k" || "$1" == "kill-session" || "$1" == "kill-ses" ]]; then
    # (Your existing 'k' logic remains unchanged)
    local target_session="$2"
    local current_session
    [[ -n "$TMUX" ]] && current_session=$(command tmux display-message -p '#S')
    if [[ -z "$target_session" && -n "$current_session" ]]; then
      if [[ "$current_session" != "default" && $(command tmux has-session -t default 2>/dev/null && echo 1) ]]; then
        command tmux switch-client -t default && command tmux kill-session -t "$current_session"
      else
        command tmux kill-session
      fi
      return $?
    fi
    if [[ -n "$target_session" ]]; then
      if [[ -n "$current_session" && "$current_session" == "$target_session" && "$current_session" != "default" && $(command tmux has-session -t default 2>/dev/null && echo 1) ]]; then
        command tmux switch-client -t default && command tmux kill-session -t "$target_session"
      else
        command tmux kill-session -t "$target_session"
      fi
      return $?
    fi
    command tmux kill-session
    return $?
  fi

  # --- Priority 2: Check for ANY other valid tmux command OR alias ---
  # This is a more robust method using awk for commands and grep for aliases.
  local -a all_tmux_commands
  all_tmux_commands=(
    # 1. Get all base command names (the first word of each line).
    ${(f)"$(command tmux list-commands | awk '{print $1}')"}
    # 2. Find all aliases like '(ls)', grep them, and remove the parentheses.
    ${(f)"$(command tmux list-commands | grep -o '([^)]*)' | tr -d '()')"}
  )

  # Check if the first argument exists as an element in the array.
  if (( ${all_tmux_commands[(Ie)$1]} )); then
    # The command IS valid. Execute it normally.
    command tmux "$@"
    return $?
  fi
  
  # --- Priority 3: Fallback to Smart "Attach-or-Create" Logic ---
  # If we get here, the command is not an alias and not a valid tmux command.
  # We now assume it's a session name.
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
