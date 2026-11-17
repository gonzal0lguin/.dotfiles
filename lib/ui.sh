# shellcheck shell=bash
# Inline terminal UI for the installer (p10k-wizard style, no whiptail).
# Everything is drawn on /dev/tty, so these work inside $(...).
#
#   ui_select  "Question" default  val1 "desc1" val2 "desc2" ...   -> prints value
#   ui_multi   "Question"          val1 "desc1" on|off ...          -> prints values, one per line
#   ui_confirm "Question" y|n                                       -> exit status

_UI_TTY=/dev/tty
_ui() { printf '%b' "$*" >"$_UI_TTY"; }

if [[ -t 1 || -t 2 ]]; then
  _u_r=$'\e[0m' _u_b=$'\e[1m' _u_d=$'\e[2m' _u_acc=$'\e[35m' _u_ok=$'\e[32m' _u_hl=$'\e[1;36m'
else
  _u_r='' _u_b='' _u_d='' _u_acc='' _u_ok='' _u_hl=''
fi

# Read one key: up, down, space, enter, esc or the character itself.
_ui_key() {
  local k rest
  IFS= read -rsn1 k <"$_UI_TTY" || { echo esc; return; }
  if [[ $k == $'\e' ]]; then
    IFS= read -rsn2 -t 0.05 rest <"$_UI_TTY" || true
    case $rest in '[A'|OA) echo up ;; '[B'|OB) echo down ;; *) echo esc ;; esac
    return
  fi
  case $k in '') echo enter ;; ' ') echo space ;; *) printf '%s\n' "$k" ;; esac
}

# Title card shown above each question.
_ui_title() {
  _ui "\e[H\e[2J\n${_u_acc}${_u_b}  ◆ dotfiles${_u_r}  ${_u_d}setup${_u_r}\n\n"
  _ui "  ${_u_b}$1${_u_r}\n\n"
}

_ui_cleanup() { _ui "\e[?25h"; }

# Move the cursor up n lines and clear down (to redraw a list in place).
_ui_rewind() { (( $1 )) && _ui "\e[$1A"; _ui "\r\e[J"; }

ui_select() {
  local q=$1 def=$2; shift 2
  local vals=() descs=() i cur=0 n key
  while (( $# )); do vals+=("$1"); descs+=("$2"); shift 2; done
  n=${#vals[@]}
  for i in "${!vals[@]}"; do [[ ${vals[i]} == "$def" ]] && cur=$i; done
  _ui_title "$q"
  _ui "\e[?25l"
  local drawn=0
  while :; do
    _ui_rewind "$drawn"
    for i in "${!vals[@]}"; do
      if (( i == cur )); then
        _ui "  ${_u_hl}❯ ($((i+1))) ${vals[i]}${_u_r}  ${descs[i]}\n"
      else
        _ui "    ${_u_d}($((i+1)))${_u_r} ${vals[i]}  ${_u_d}${descs[i]}${_u_r}\n"
      fi
    done
    _ui "\n  ${_u_d}↑/↓ move · 1-$n pick · enter confirm · q quit${_u_r}\n"
    drawn=$((n + 2))
    key=$(_ui_key)
    case $key in
      up|k) cur=$(( (cur - 1 + n) % n )) ;;
      down|j) cur=$(( (cur + 1) % n )) ;;
      [1-9]) (( key <= n )) && { cur=$((key - 1)); break; } ;;
      enter) break ;;
      q|esc) _ui_cleanup; _ui "\n"; die "cancelled" ;;
    esac
  done
  _ui_rewind "$drawn"; _ui_cleanup
  _ui "  ${_u_ok}✔${_u_r} ${vals[cur]}\n"
  printf '%s\n' "${vals[cur]}"
}

ui_multi() {
  local q=$1; shift
  local vals=() descs=() on=() i cur=0 n key w=0
  while (( $# )); do
    vals+=("$1"); descs+=("$2"); [[ ${3,,} == on ]] && on+=(1) || on+=(0); shift 3
    (( ${#vals[-1]} > w )) && w=${#vals[-1]}
  done
  n=${#vals[@]}
  _ui_title "$q"
  _ui "\e[?25l"
  local drawn=0 box
  while :; do
    _ui_rewind "$drawn"
    for i in "${!vals[@]}"; do
      (( on[i] )) && box="${_u_ok}◉${_u_r}" || box="${_u_d}○${_u_r}"
      if (( i == cur )); then
        _ui "  ${_u_hl}❯${_u_r} $box ${_u_hl}$(printf "%-${w}s" "${vals[i]}")${_u_r}  ${descs[i]}\n"
      else
        _ui "    $box $(printf "%-${w}s" "${vals[i]}")  ${_u_d}${descs[i]}${_u_r}\n"
      fi
    done
    _ui "\n  ${_u_d}↑/↓ move · space toggle · a all · n none · enter confirm · q quit${_u_r}\n"
    drawn=$((n + 2))
    key=$(_ui_key)
    case $key in
      up|k) cur=$(( (cur - 1 + n) % n )) ;;
      down|j) cur=$(( (cur + 1) % n )) ;;
      space|x) on[cur]=$(( ! on[cur] )) ;;
      a) for i in "${!on[@]}"; do on[i]=1; done ;;
      n) for i in "${!on[@]}"; do on[i]=0; done ;;
      enter) break ;;
      q|esc) _ui_cleanup; _ui "\n"; die "cancelled" ;;
    esac
  done
  _ui_rewind "$drawn"; _ui_cleanup
  local picked=()
  for i in "${!vals[@]}"; do (( on[i] )) && picked+=("${vals[i]}"); done
  _ui "  ${_u_ok}✔${_u_r} ${picked[*]:-nothing}\n"
  for i in "${picked[@]}"; do printf '%s\n' "$i"; done
}

ui_confirm() {
  local q=$1 def=${2:-y} key
  _ui_title "$q"
  local yes="(y) Yes" no="(n) No"
  if [[ $def == y ]]; then yes="${_u_hl}❯ $yes${_u_r}"; no="  ${_u_d}$no${_u_r}"
  else no="${_u_hl}❯ $no${_u_r}"; yes="  ${_u_d}$yes${_u_r}"; fi
  _ui "  $yes\n  $no\n\n  ${_u_d}y / n · enter = default · q quit${_u_r}\n"
  while :; do
    key=$(_ui_key)
    case $key in
      y|Y) def=y; break ;;
      n|N) def=n; break ;;
      enter) break ;;
      q|esc) _ui "\n"; die "cancelled" ;;
    esac
  done
  _ui_rewind 4
  _ui "  ${_u_ok}✔${_u_r} $([[ $def == y ]] && echo yes || echo no)\n"
  [[ $def == y ]]
}
