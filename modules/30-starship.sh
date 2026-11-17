# shellcheck shell=bash
module starship on "Starship prompt"

starship_install() {
  if has starship; then
    ok "starship $(starship --version | head -1 | awk '{print $2}') already installed"
  elif (( DRY_RUN )); then
    info "[dry-run] install starship to $LOCAL_BIN"
  else
    mkdir -p "$LOCAL_BIN"
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$LOCAL_BIN" >/dev/null
    ok "installed starship"
  fi
  link_pkg starship
  # regenerate the themed copy (~/.config/dotfiles/starship.toml)
  apply_theme "$(state_get THEME catppuccin-mocha)" >/dev/null
}
