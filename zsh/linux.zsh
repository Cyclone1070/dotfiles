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

    sunshine() {
      case $1 in
        up)
          systemctl --user start app-dev.lizardbyte.app.Sunshine.service
          ;;
        down)
          systemctl --user stop app-dev.lizardbyte.app.Sunshine.service
          ;;
        status)
          systemctl --user status app-dev.lizardbyte.app.Sunshine.service
          ;;
        logs)
          journalctl --user -u app-dev.lizardbyte.app.Sunshine.service -f
          ;;
        *)
          echo "Usage: sunshine {up|down|status|logs}"
          return 1
          ;;
      esac
    }
fi
export PATH="$HOME/repos/dotfiles/bin/linux:$PATH"
