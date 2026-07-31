# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# === Custom config ===
[[ -f "$HOME/repos/dotfiles/zsh/secrets.zsh" ]] && source "$HOME/repos/dotfiles/zsh/secrets.zsh"
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

# sssh Zsh Integration Hook

sssh-accept-line() {
    if sssh check-intercept "$BUFFER" "$PWD"; then
        BUFFER="sssh $BUFFER"
    fi
    zle sssh-orig-accept-line
}

() {
    if [[ "$widgets[accept-line]" != "user:sssh-accept-line" ]]; then
        local sssh_orig_widget="${widgets[accept-line]}"
        if [[ "$sssh_orig_widget" == *:* ]]; then
            sssh_orig_widget="${sssh_orig_widget#*:}"
            zle -N sssh-orig-accept-line "$sssh_orig_widget"
        else
            sssh-orig-accept-line() {
                zle .accept-line
            }
            zle -N sssh-orig-accept-line
        fi
        zle -N accept-line sssh-accept-line
    fi
}

# Run sync in background on terminal startup to restore links, syncs, and listeners
(sssh sync >/dev/null 2>&1 &)

