# bin instead of rm
alias bi='trash'
# look inside trash
alias bil='lsd -ltr --group-dirs=first --date=relative --blocks=date,name ~/.Trash'
# enhanced ls
alias ls='lsd -ltr --group-dirs=first --date=relative --blocks=size,date,git,name'
alias lsa='lsd -a -ltr --group-dirs=first --date=relative --blocks=size,date,name'
#nethack 
alias nethack='ssh -o SetEnv="DGLAUTH=cyclone1070:h0angmai" nethack@au.hardfought.org'
# quicklook
alias ql='qlmanage -p'
# opencode
alias vibe='opencode --agent router'
alias ai='opencode --agent generalist'
# mongo
alias mstart='brew services start mongodb-community@8.0'
alias mstop='brew services stop mongodb-community@8.0'
# autossh to enable and disable ssh portforwarding from remote oracle linux instance
alias remoteon='launchctl load ~/Library/LaunchAgents/com.oracle.tunnel.plist && pmset displaysleepnow'
alias remoteoff='launchctl unload ~/Library/LaunchAgents/com.oracle.tunnel.plist'
alias remotecheck='ps aux | grep "[a]utossh"'
# map cd to zoxide
alias cd='z'
# build mac mouse fix
# open with: open ~/Library/Developer/Xcode/DerivedData/Mouse_Fix-*/Build/Products/Release/

buildmousefix() {
    cd ~/Desktop/repos/mac-mouse-fix && \
    xcodebuild clean -scheme "App - Release" && \
    xcodebuild clean -scheme "Helper - Release" && \
    xcodebuild -scheme "Helper - Release" SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) FORCE_LICENSED FORCE_NOT_EXPIRED' && \
    xcodebuild -scheme "App - Release" SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) FORCE_LICENSED FORCE_NOT_EXPIRED'
}
# Function to remove hyphens and overwrite the original file
function epubfix() {
  local input="$1"
  local temp="${input%.*}_temp.epub"
  
  /Applications/calibre.app/Contents/MacOS/ebook-convert "$input" "$temp" --extra-css "body { -epub-hyphens: none; -webkit-hyphens: none; hyphens: none; }" && mv "$temp" "$input"
}
