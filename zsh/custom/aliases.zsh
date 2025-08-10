# bin instead of rm
alias bi='trash'
# look inside trash
alias bil='lsd -ltr --group-dirs=first --date=relative --blocks=date,name ~/.Trash'
# enhanced ls
alias ls='lsd -ltr --group-dirs=first --date=relative --blocks=size,date,name'
alias lsa='lsd -a -ltr --group-dirs=first --date=relative --blocks=size,date,name'
#nethack 
alias nethack='ssh -o SetEnv="DGLAUTH=cyclone1070:h0angmai" nethack@au.hardfought.org'
# quicklook
alias ql='qlmanage -p'
# neovide
alias vide='neovide --fork'
# mongo
alias mstart='brew services start mongodb-community@8.0'
alias mstop='brew services stop mongodb-community@8.0'
# gemini cli
alias geminif="gemini -m gemini-2.5-flash"
# autossh to enable and disable ssh portforwarding from remote oracle linux instance
alias remoteon='launchctl load ~/Library/LaunchAgents/com.autossh.tunnel.plist && pmset displaysleepnow'
alias remoteoff='launchctl unload ~/Library/LaunchAgents/com.autossh.tunnel.plist'
alias remotecheck='ps aux | grep "[a]utossh"'


# Setup a tmux session for react workflow
treact() {
  if [[ -z "$1" ]]; then
    echo "Usage: treact <directory>"
    return 1
  fi

  local dir_path
  dir_path=$(realpath "$1")

  if [[ ! -d "$dir_path" ]]; then
    echo "Error: '$dir_path' is not a directory."
    return 1
  fi

  local original_hook
  original_hook=$(tmux show-hooks -g | grep 'session-created')

  # Set a trap to restore the hook when the function exits (for any reason).
  if [[ -n "$original_hook" ]]; then
    trap "tmux set-hook -g ${original_hook}" EXIT
  else
    trap "tmux set-hook -g -u session-created" EXIT
  fi

  # Unset the hook for the duration of this function's execution.
  tmux set-hook -g -u session-created

  local dir_name
  dir_name=$(basename "$dir_path")
  local session_name=${dir_name//./_}

  # Create the sessions
  tmux new-session -d -s "$session_name" -c "$dir_path"

  local h_session_name="h$session_name"
  tmux new-session -d -s "$h_session_name" -c "$dir_path"
  tmux send-keys -t "$h_session_name" "pnpm dev --host" C-m

  local n_session_name="n$session_name"
  tmux new-session -d -s "$n_session_name" -c "$dir_path"
  tmux send-keys -t "$n_session_name" "nvim" C-m

  tmux switch-client -t "$n_session_name"

  # The trap will automatically fire now, restoring the hook.
}
