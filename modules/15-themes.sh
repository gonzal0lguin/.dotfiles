# shellcheck shell=bash
module themes on "Color theme for every app (catppuccin-mocha / gruvbox-dark)"

themes_configure() {
  local cur; cur=${THEME:-$(state_get THEME catppuccin-mocha)}
  THEME=$(choose "Color theme (switch later with: dot theme <name>)" "$cur" \
    catppuccin-mocha "Catppuccin Mocha (pastel)" \
    gruvbox-dark "Gruvbox Dark (warm, retro)")
  export THEME
}

themes_install() {
  apply_theme "${THEME:-$(state_get THEME catppuccin-mocha)}"
}
