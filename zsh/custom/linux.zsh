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

    wolf() {
      case $1 in
        up)
          sudo systemctl start wolf
          ;;
        down)
          sudo systemctl stop wolf
          ;;
        status)
          sudo systemctl status wolf
          ;;
        logs)
          sudo podman logs -f wolf
          ;;
        *)
          echo "Usage: wolf {up|down|status|logs}"
          return 1
          ;;
      esac
    }
fi
export PATH="$HOME/repos/dotfiles/bin/linux:$PATH"
