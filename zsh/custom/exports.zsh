export GREP_OPTIONS='--color=auto'
export LANG="en_US.UTF-8"
export LC_COLLATE="C"
export DOTNET_ROOT="/usr/local/Cellar/dotnet/9.0.7/libexec"
export PATH="$HOME/Library/Python/3.9/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.dotnet/tools:$PATH"
export PATH="/Users/mac/go/bin:$PATH"

# Disable Homebrew's built-in auto-update
export HOMEBREW_NO_AUTO_UPDATE="1"

# pnpm
export PNPM_HOME="/Users/mac/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
