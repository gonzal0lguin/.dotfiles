# ~/.zshrc — managed by dotfiles (https://github.com/gonzal0lguin/.dotfiles)
# Everything lives in ~/.config/zsh. Put machine-specific things in
# ~/.config/zsh/local.zsh and tokens in ~/.config/zsh/secrets.zsh (both untracked).

ZSH_CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/zsh

for _f in env options secrets plugins keybinds aliases functions fzf docker claude tools local; do
  [[ -r $ZSH_CONFIG/$_f.zsh ]] && source "$ZSH_CONFIG/$_f.zsh"
done
unset _f
