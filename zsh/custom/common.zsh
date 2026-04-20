# Common Aliases & Exports (Cross-Platform)

# bin instead of rm (If trash exists)
if command -v trash >/dev/null 2>&1; then
    alias bi='trash'
fi

# enhanced ls
alias ls='lsd -ltr --group-dirs=first --date=relative --blocks=size,date,git,name'
alias lsa='lsd -a -ltr --group-dirs=first --date=relative --blocks=size,date,name'

# nethack 
alias nethack='ssh -o SetEnv="DGLAUTH=cyclone1070:h0angmai" nethack@au.hardfought.org'

# opencode
alias vibe='opencode --agent router'
alias ai='opencode --agent generalist'

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
