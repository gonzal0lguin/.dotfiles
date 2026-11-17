# shellcheck shell=bash
module defterm off "Make alacritty or kitty the default terminal (Ctrl+Alt+T)"

defterm_configure() {
  DEFAULT_TERMINAL=$(choose "Default terminal" "${DEFAULT_TERMINAL:-$(state_get DEFAULT_TERMINAL alacritty)}" \
    alacritty "Alacritty" kitty "kitty")
  export DEFAULT_TERMINAL
}

defterm_install() {
  local t=${DEFAULT_TERMINAL:-$(state_get DEFAULT_TERMINAL alacritty)} path
  path=$(command -v "$t" || true)
  [[ $t == kitty && -x $HOME/.local/kitty.app/bin/kitty ]] && path=$HOME/.local/kitty.app/bin/kitty
  [[ -n $path ]] || { err "$t is not installed"; return 1; }
  state_set DEFAULT_TERMINAL "$t"
  if (( ! NO_PACKAGES )); then
    run $SUDO update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$path" 60
    run $SUDO update-alternatives --set x-terminal-emulator "$path"
  fi
  if has gsettings; then
    run gsettings set org.gnome.desktop.default-applications.terminal exec "$path" || true
  fi
  ok "default terminal: $t"
}
