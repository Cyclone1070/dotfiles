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
