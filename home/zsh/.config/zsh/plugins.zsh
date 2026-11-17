# Plugin manager: antidote. Clones itself on first start if missing.

ANTIDOTE_DIR=$XDG_DATA_HOME/antidote
if [[ ! -r $ANTIDOTE_DIR/antidote.zsh ]] && (( $+commands[git] )); then
  print -P "%F{blue}Installing antidote (zsh plugin manager)...%f"
  git clone -q --depth=1 https://github.com/mattmc3/antidote $ANTIDOTE_DIR
fi

if [[ -r $ANTIDOTE_DIR/antidote.zsh ]]; then
  zstyle ':antidote:bundle' use-friendly-names 'yes'
  source $ANTIDOTE_DIR/antidote.zsh
  antidote load $ZSH_CONFIG/plugins.txt $XDG_CACHE_HOME/zsh/plugins.zsh
else
  # no git / offline: still get a working completion system
  source $ZSH_CONFIG/plugins/completion/completion.plugin.zsh
fi

# plugin settings
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=50
