# macOS Specific Configuration
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Paths
    export PATH="$HOME/Library/Python/3.9/bin:$PATH"
    export PATH="$HOME/.dotnet/tools:$PATH"
    export DOTNET_ROOT="/usr/local/share/dotnet"
    export PNPM_HOME="$HOME/Library/pnpm"
    
    case ":$PATH:" in
      *":$PNPM_HOME:"*) ;;
      *) export PATH="$PNPM_HOME:$PATH" ;;
    esac

    # Aliases
    alias bil='lsd -ltr --group-dirs=first --date=relative --blocks=date,name ~/.Trash'
    alias ql='qlmanage -p'
    alias mstart='brew services start mongodb-community@8.0'
    alias mstop='brew services stop mongodb-community@8.0'
    alias remoteon='launchctl load ~/Library/LaunchAgents/com.oracle.tunnel.plist && pmset displaysleepnow'
    alias remoteoff='launchctl unload ~/Library/LaunchAgents/com.oracle.tunnel.plist'
    alias remotecheck='ps aux | grep "[a]utossh"'
    alias brewup="brew update && brew upgrade && brew cleanup"
    alias iav='~/repos/iav/iav'
    
    # Functions
    buildmousefix() {
        cd ~/repos/mac-mouse-fix && \
        xcodebuild clean -scheme "App - Release" && \
        xcodebuild clean -scheme "Helper - Release" && \
        xcodebuild -scheme "Helper - Release" SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) FORCE_LICENSED FORCE_NOT_EXPIRED' -allowProvisioningUpdates && \
        xcodebuild -scheme "App - Release" SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) FORCE_LICENSED FORCE_NOT_EXPIRED' -allowProvisioningUpdates
    }

    epubfix() {
        if [ $# -eq 0 ]; then
            echo "Usage: epubfix <file1.epub> [file2.epub] [...]"
            return 1
        fi
        for input in "$@"; do
            if [ ! -f "$input" ]; then
                echo "Error: '$input' not found, skipping..."
                continue
            fi
            local temp="${input%.*}_temp.epub"
            echo "Processing: $input"
            /Applications/calibre.app/Contents/MacOS/ebook-convert "$input" "$temp" \
                --extra-css "body { -epub-hyphens: none; -webkit-hyphens: none; hyphens: none; }" \
                --filter-css "font-family" \
                && mv "$temp" "$input" \
                && echo "✓ Completed: $input" \
                || echo "✗ Failed: $input"
        done
    }

    # Homebrew
    export HOMEBREW_NO_AUTO_UPDATE="1"
fi
