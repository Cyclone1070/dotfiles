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
alias azureon='launchctl load ~/Library/LaunchAgents/com.azure.tunnel.plist && pmset displaysleepnow'
alias azureoff='launchctl unload ~/Library/LaunchAgents/com.azure.tunnel.plist'
alias oracleon='launchctl load ~/Library/LaunchAgents/com.oracle.tunnel.plist && pmset displaysleepnow'
alias oracleoff='launchctl unload ~/Library/LaunchAgents/com.oracle.tunnel.plist'
alias remotecheck='ps aux | grep "[a]utossh"'
# map cd to zoxide
alias cd='z'


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

  local current_session_name
  current_session_name=$(tmux display-message -p '#S')

  local dir_name
  dir_name=$(basename "$dir_path")
  local window_base_name=${dir_name//./_}

  # Create the first window with just the directory name
  tmux new-window -n "$window_base_name" -c "$dir_path"

  # Create a new window for pnpm dev --host
  local h_window_name="h$window_base_name"
  tmux new-window -n "$h_window_name" -c "$dir_path"
  tmux send-keys -t "$current_session_name:$h_window_name" "pnpm dev --host" C-m

  # Create a new window for nvim
  local n_window_name="n$window_base_name"
  tmux new-window -n "$n_window_name" -c "$dir_path"
  tmux send-keys -t "$current_session_name:$n_window_name" "nvim" C-m

  # Select the nvim window
  tmux select-window -t "$current_session_name:$n_window_name"
}
