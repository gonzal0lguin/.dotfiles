# shellcheck shell=bash
module fzf on "fzf (latest release; Ubuntu's is too old for 'fzf --zsh')"

_fzf_version() { fzf --version 2>/dev/null | awk '{print $1}'; }

fzf_install() {
  local have want=0.48
  have=$(_fzf_version)
  if [[ -n $have ]] && [[ $(printf '%s\n%s\n' "$want" "$have" | sort -V | head -1) == "$want" ]]; then
    ok "fzf $have is recent enough"; return 0
  fi
  local tag; tag=$(gh_latest_tag junegunn/fzf) || { err "cannot reach GitHub"; return 1; }
  install_release_bin fzf \
    "https://github.com/junegunn/fzf/releases/download/${tag}/fzf-${tag#v}-linux_$(arch_name amd64).tar.gz"
}
