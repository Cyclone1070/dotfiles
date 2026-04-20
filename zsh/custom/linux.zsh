# Linux Specific Configuration
if [[ "$OSTYPE" != "darwin"* ]]; then
    # Node.js Rootless Prefix
    export PATH="$HOME/.npm-global/bin:$PATH"
    
    # Add any Linux-specific aliases here
    # alias dnfup="sudo dnf update -y"
fi
