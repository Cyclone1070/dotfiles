# Linux Specific Configuration
if [[ "$OSTYPE" != "darwin"* ]]; then
    # Node.js Rootless Prefix
    export PATH="$HOME/.npm-global/bin:$PATH"
    
    # Add any Linux-specific aliases here
    # alias dnfup="sudo dnf update -y"

    # aria2 RPC Configuration
    export ARIA2_RPC_URL="http://localhost:6800/jsonrpc"

    # Push a URL to the background aria2 daemon
    dl() {
      if [ -z "$1" ]; then
        echo "Usage: dl <URL>"
        return 1
      fi
      aria2p add "$1"
    }

    # Check status of active downloads (Interactive Dashboard)
    dls() {
      aria2p top
    }

    # Add a Non-Steam Game to the library via CLI
    addgame() {
      local exe="$1"
      local name="$2"
      if [ -z "$exe" ] || [ -z "$name" ]; then
        echo "Usage: addgame <path/to/exe> <Game Name>"
        return 1
      fi

      # Check if Steam is running
      if pgrep -x "steam" > /dev/null; then
        echo "Steam is running. Steam must be closed to inject the shortcut."
        echo -n "Kill Steam now? (y/n) "
        read -r choice
        if [ "$choice" = "y" ]; then
          pkill -TERM steam
          sleep 2
        else
          echo "Operation cancelled."
          return 1
        fi
      fi

      # Absolute path
      local abs_exe=$(readlink -f "$exe")

      # Inject via STL
      steamtinkerlaunch addnonsteamgame --exepath="$abs_exe" --appname="$name" --compatibilitytool="proton_9"

      echo "Game '$name' added to Steam with Proton 9.0 compatibility."
    }
fi
