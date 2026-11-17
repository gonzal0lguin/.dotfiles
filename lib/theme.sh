# shellcheck shell=bash
# Theme switching: one folder per theme in themes/, selected with a symlink
#   ~/.config/dotfiles/current -> <repo>/themes/<name>
# Apps read their theme file through that link (alacritty import, kitty include,
# zsh shell.zsh, vim vim.vim). Starship and btop get generated/edited configs.

THEMES_DIR="$DOTFILES_DIR/themes"

list_themes() {
  local cur d n
  cur=$(state_get THEME)
  for d in "$THEMES_DIR"/*/; do
    n=$(basename "$d")
    if [[ $n == "$cur" ]]; then printf '* %s\n' "$n"; else printf '  %s\n' "$n"; fi
  done
}

apply_theme() {
  local name=$1 dir="$THEMES_DIR/$1"
  [[ -d $dir ]] || die "unknown theme '$name'. Available: $(cd "$THEMES_DIR" && echo */ | tr -d /)"
  local STARSHIP_PALETTE="" BTOP_THEME=""
  # shellcheck source=/dev/null
  source "$dir/theme.sh"

  run mkdir -p "$STATE_DIR"
  run ln -sfn "$dir" "$STATE_DIR/current"
  state_set THEME "$name"

  # starship: same config, different palette (first line of the base file)
  local base="$DOTFILES_DIR/home/starship/.config/starship.toml"
  if (( ! DRY_RUN )); then
    sed "1s/^palette = .*/palette = '$STARSHIP_PALETTE'/" "$base" >"$STATE_DIR/starship.toml"
  fi

  # btop rewrites its own config, so edit it in place instead of linking it
  local btop_conf="${XDG_CONFIG_HOME:-$HOME/.config}/btop/btop.conf"
  if [[ -f $btop_conf ]]; then
    run sed -i "s/^color_theme = .*/color_theme = \"$BTOP_THEME\"/" "$btop_conf"
  elif (( ! DRY_RUN )); then
    mkdir -p "$(dirname "$btop_conf")"
    echo "color_theme = \"$BTOP_THEME\"" >"$btop_conf"
  fi

  # live reload what can be reloaded (DOTFILES_NO_RELOAD=1 skips it, e.g. in tests)
  if (( ! DRY_RUN )) && [[ -z ${DOTFILES_NO_RELOAD:-} ]]; then
    pkill -USR1 -x kitty 2>/dev/null || true                       # kitty re-reads its config
    local ala="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/alacritty.toml"
    [[ -e $ala ]] && touch "$ala"                                  # alacritty live reload
  fi
  ok "theme: $name  (new shells pick up fzf/bat/prompt colors; restart vim)"
}
