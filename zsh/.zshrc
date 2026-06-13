# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# === Custom config ===
source "$HOME/repos/dotfiles/zsh/secrets.zsh"
source "$HOME/repos/dotfiles/zsh/common.zsh"
source "$HOME/repos/dotfiles/zsh/macos.zsh"
source "$HOME/repos/dotfiles/zsh/linux.zsh"

# === Plugins ===
source "$HOME/repos/dotfiles/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOME/repos/dotfiles/zsh/plugins/zsh-autopair/zsh-autopair.plugin.zsh"
source "$HOME/repos/dotfiles/zsh/plugins/marked-operations/marked-operations.plugin.zsh"
source "$HOME/repos/dotfiles/zsh/plugins/tmux-windows/tmux-windows.plugin.zsh"
# syntax-highlighting MUST be sourced last
source "$HOME/repos/dotfiles/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# === p10k standalone ===
source "$HOME/repos/dotfiles/zsh/themes/powerlevel10k/powerlevel10k.zsh-theme"

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
eval "$(zoxide init zsh)"
