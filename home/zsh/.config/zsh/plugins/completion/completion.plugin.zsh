# Completion system. Loaded from plugins.txt (local plugin) so it runs after plugins that add
# to fpath and before fzf-tab.

autoload -Uz compinit
() {
  setopt local_options extended_glob
  local dump=$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION
  mkdir -p ${dump:h}
  # full security check at most once a day, otherwise trust the cache (faster)
  if [[ -n $dump(#qN.mh-24) ]]; then
    compinit -C -d $dump
  else
    compinit -d $dump
  fi
}

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no                        # fzf-tab shows the menu
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path $XDG_CACHE_HOME/zsh/zcompcache
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*' special-dirs true

# fzf-tab: previews
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' fzf-flags --height=50%
zstyle ':fzf-tab:complete:(cd|z|ls|eza):*' fzf-preview \
  'eza -1 --color=always --icons $realpath 2>/dev/null || ls -1 --color=always $realpath'
zstyle ':fzf-tab:complete:(vim|bat|cat|less):*' fzf-preview \
  '[[ -f $realpath ]] && bat --color=always --style=numbers --line-range=:80 $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps -o pid,user,%cpu,%mem,cmd -p $word'

# Ubuntu: suggest the package for unknown commands
[[ -r /etc/zsh_command_not_found ]] && source /etc/zsh_command_not_found
