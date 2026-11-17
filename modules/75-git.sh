# shellcheck shell=bash
module git on "git config (delta pager, aliases); identity in untracked ~/.gitconfig.local"

git_install() {
  apt_install git git-delta
  local old="$HOME/.gitconfig" localcfg="$HOME/.gitconfig.local" name="" email=""

  if [[ ! -f $localcfg ]]; then
    if [[ -f $old && ! -L $old ]]; then
      name=$(git config -f "$old" user.name || true)
      email=$(git config -f "$old" user.email || true)
    fi
    name=${name:-${GIT_NAME:-}} email=${email:-${GIT_EMAIL:-}}
    if [[ -z $name || -z $email ]] && (( ! ASSUME_YES )) && [[ -t 0 ]]; then
      read -r -p "git user.name: " name
      read -r -p "git user.email: " email
    fi
    if [[ -n $name && -n $email ]] && (( ! DRY_RUN )); then
      git config -f "$localcfg" user.name "$name"
      git config -f "$localcfg" user.email "$email"
      ok "wrote identity to $localcfg"
    else
      manual "Set your git identity: git config -f ~/.gitconfig.local user.name '...' && git config -f ~/.gitconfig.local user.email '...'"
    fi
  else
    ok "kept $localcfg"
  fi

  # ~/.gitconfig would override ~/.config/git/config
  if [[ -e $old || -L $old ]] && ! _points_to_repo "$old"; then backup_path "$old"; fi
  link_pkg git
  has gh && gh auth status >/dev/null 2>&1 && manual "Optional: let git use your GitHub CLI login: gh auth setup-git"
  return 0
}
