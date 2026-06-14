# Common Aliases & Exports (Cross-Platform)

# === History ===
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000
setopt extended_history hist_expire_dups_first hist_ignore_dups hist_verify share_history

# === Smart ↑ history search ===
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# === Completion ===
zmodload -i zsh/complist
unsetopt menu_complete flowcontrol
setopt auto_menu complete_in_word always_to_end
autoload -U compinit bashcompinit && compinit -u && bashcompinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$HOME/.cache/zsh/completions"
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# bin instead of rm (If trash exists)
if command -v trash >/dev/null 2>&1; then
    alias bi='trash'
fi

# enhanced ls
alias ls='lsd -ltr --group-dirs=first --date=relative --blocks=size,date,git,name'
alias lsa='lsd -a -ltr --group-dirs=first --date=relative --blocks=size,date,name'

# nethack 
alias nethack='ssh -o SetEnv="DGLAUTH=cyclone1070:h0angmai" nethack@au.hardfought.org'

# map cd to zoxide
alias cd='z'

# Common Exports
export GREP_OPTIONS='--color=auto'
export LANG="en_US.UTF-8"
export LC_COLLATE="C"

# Common Paths
export PATH="$HOME/.local/bin:$PATH"

# Keymaps
bindkey -r '^L'
bindkey '^L' autosuggest-accept

# radio/music settings
alias abc='mpv http://www.abc.net.au/res/streaming/audio/aac/news_radio.pls'
alias bgm="mpv --volume=50 --no-video --loop-playlist --volume-max=300 --display-tags= --script-opts=stats-key_page_0=6 --script=$HOME/repos/dotfiles/zsh/scripts/auto-stats.lua 'https://www.youtube.com/playlist?list=PLkVD01XL1G9LNt5iprsJYrqOcqtYNUh3e'"
alias music="mpv --volume=70 --no-video --loop-playlist --volume-max=300 --display-tags= --script-opts=stats-key_page_0=6 --script=$HOME/repos/dotfiles/zsh/scripts/auto-stats.lua 'https://www.youtube.com/playlist?list=PLkVD01XL1G9JAFImX9SrKa_GXQxRuESuU'"

# Opencode settings
export OPENCODE_ENABLE_EXA=1

# Pi settings
alias ai='pi'
export EDITOR='nvim'

# Export languages bin paths
export PATH="$PATH:$HOME/go/bin"
export PATH="$PATH:$HOME/.bun/bin"
