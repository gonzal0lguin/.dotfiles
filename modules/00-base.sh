# shellcheck shell=bash
module base on "Core packages (git, curl, stow, jq, whiptail...) + the 'dot' command"

base_install() {
  apt_install git curl wget ca-certificates gnupg stow jq unzip xz-utils fontconfig whiptail
  run mkdir -p "$LOCAL_BIN" "$STATE_DIR"
  state_set DOTFILES_DIR "$DOTFILES_DIR"
  link_pkg bin
  case ":$PATH:" in
    *":$LOCAL_BIN:"*) ;;
    *) info "$LOCAL_BIN is not in PATH yet; the zsh config adds it" ;;
  esac
}
