# Aliases. Machine-specific ones go in local.zsh.

# navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# files
alias rmf='rm -rf'
alias cl='clear'
alias lg='ls | grep'
alias open='xdg-open'
alias df='df -h'
alias du1='du -h -d 1'

# Ubuntu names some tools differently (the installer adds bat/fd shims too)
(( $+commands[batcat] && ! $+commands[bat] )) && alias bat='batcat'
(( $+commands[fdfind] && ! $+commands[fd] )) && alias fd='fdfind'

# ls -> eza when available
if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -l --group-directories-first --icons=auto --git'
  alias la='eza -la --group-directories-first --icons=auto --git'
  alias lt='eza --tree --level=2 --icons=auto'
else
  alias ls='ls --color=auto'
  alias ll='ls -lh'
  alias la='ls -lAh'
fi

alias grep='grep --color=auto'
alias g='git'
(( $+commands[lazygit] )) && alias lzg='lazygit'
(( $+commands[lazydocker] )) && alias lzd='lazydocker'

# reload the shell config
alias reload='exec zsh'
