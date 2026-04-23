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
      curl -s -d "{\"jsonrpc\":\"2.0\",\"method\":\"aria2.addUri\",\"id\":\"ansible\",\"params\":[[\"$1\"]]}" "$ARIA2_RPC_URL" | jq .
    }

    # Check status of active downloads
    dls() {
      curl -s -d '{"jsonrpc":"2.0","method":"aria2.tellActive","id":"ansible","params":[]}' "$ARIA2_RPC_URL" \
      | jq -r '.result[] | "GID: \(.gid) | Status: \(.status) | Speed: \((.downloadSpeed | tonumber) / 1024 / 1024 | . * 100 | round / 100) MB/s | Progress: \(((.completedLength | tonumber) / ((.totalLength | tonumber) + 0.000001) * 100) | round)%"'
    }
fi
