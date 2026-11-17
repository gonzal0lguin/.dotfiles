# Environment: PATH, XDG dirs, editor, dotfiles location.

# Snap-packaged apps (e.g. the alacritty snap) leak their own XDG_CACHE_HOME
# into every shell they start; put caches back where they belong.
[[ $XDG_CACHE_HOME == */snap/* ]] && export XDG_CACHE_HOME=$HOME/.cache
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}

typeset -U path fpath   # no duplicates
path=($HOME/.local/bin $HOME/bin(N) $path)
[[ -r $HOME/.cargo/env ]] && source $HOME/.cargo/env

export EDITOR=vim VISUAL=vim
export PAGER=less LESS='-R -F -i -M'
export LANG=${LANG:-en_US.UTF-8}

# Where the dotfiles repo is (written by install.sh)
if [[ -r $XDG_CONFIG_HOME/dotfiles/config ]]; then
  export DOTFILES_DIR=${$(sed -n 's/^DOTFILES_DIR=//p' $XDG_CONFIG_HOME/dotfiles/config):-$HOME/.dotfiles}
else
  export DOTFILES_DIR=$HOME/.dotfiles
fi

# Theme (fzf colors, BAT_THEME, ...) — switched with `dot theme <name>`
[[ -r $XDG_CONFIG_HOME/dotfiles/current/shell.zsh ]] && source $XDG_CONFIG_HOME/dotfiles/current/shell.zsh
# Starship config generated for the current theme
[[ -r $XDG_CONFIG_HOME/dotfiles/starship.toml ]] && export STARSHIP_CONFIG=$XDG_CONFIG_HOME/dotfiles/starship.toml

(( $+commands[dircolors] )) && eval "$(dircolors -b)"
