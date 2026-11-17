# Docker helpers. Pickers use fzf; pass a name to skip the picker.
(( $+commands[docker] )) || return 0

alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f --tail=200'

# tidy listings
dps()  { docker ps "$@" --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'; }
dimg() { docker images "$@" --format 'table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedSince}}'; }

# _dpick [-a all containers] [-m multi]  -> prints container name(s)
_dpick() {
  local -a ps_args fzf_args
  while (( $# )); do
    case $1 in -a) ps_args+=(-a) ;; -m) fzf_args+=(-m) ;; esac
    shift
  done
  docker ps $ps_args --format '{{.Names}}\t{{.Image}}\t{{.Status}}' |
    fzf $fzf_args --delimiter='\t' --header='container  (tab = select several)' \
      --preview 'docker inspect -f "{{.Config.Image}}  {{.State.Status}}  started {{.State.StartedAt}}" {1}; docker logs --tail 20 {1} 2>&1' |
    cut -f1
}

# shell inside a container (bash if it has it)
dsh() {
  local c=${1:-$(_dpick)}; [[ -n $c ]] || return 1
  docker exec -it "$c" sh -c 'command -v bash >/dev/null && exec bash || exec sh'
}
# follow logs:  dlogs [name] [lines]
dlogs() {
  local c=${1:-$(_dpick -a)}; [[ -n $c ]] || return 1
  docker logs -f --tail="${2:-200}" "$c"
}
dstop() { local -a c=(${(f)"$(_dpick -m)"}); (( $#c )) && docker stop $c; }
drm()   { local -a c=(${(f)"$(_dpick -a -m)"}); (( $#c )) && docker rm $c; }
drmi() {
  local -a ids=(${(f)"$(docker images --format '{{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}' |
    fzf -m --delimiter='\t' --header='images to remove (tab = select several)' | cut -f2)"})
  (( $#ids )) && docker rmi $ids
}
# container IP(s)
dip() {
  local c=${1:-$(_dpick)}; [[ -n $c ]] || return 1
  docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}: {{$v.IPAddress}}{{"\n"}}{{end}}' "$c"
}
# free disk space, asking before each level
dclean() {
  docker system df
  print
  if read -q "?Remove stopped containers, dangling images, unused networks, build cache? [y/N] "; then
    print; docker system prune -f
  fi
  print
  if read -q "?ALSO remove every unused image and ALL unused volumes (data!)? [y/N] "; then
    print; docker system prune -a --volumes -f
  fi
  print
}

# dgui <image> [cmd...] — run a GUI app (rviz, gazebo, ...) with X11, host
# network, GPU when available and the current directory mounted at /work.
dgui() {
  (( $# )) || { print "usage: dgui <image> [command...]"; return 1; }
  local img=$1; shift
  local -a extra
  if (( $+commands[nvidia-smi] )) && docker info 2>/dev/null | grep -qi 'runtimes:.*nvidia'; then
    extra+=(--gpus all -e NVIDIA_DRIVER_CAPABILITIES=all)
  fi
  [[ -d /dev/dri ]] && extra+=(--device /dev/dri)
  (( $+commands[xhost] )) && xhost +si:localuser:root >/dev/null
  docker run -it --rm --net=host --ipc=host \
    -e DISPLAY -e QT_X11_NO_MITSHM=1 -e ROS_DOMAIN_ID \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw -v "$PWD":/work -w /work \
    $extra "$img" "$@"
}

# dpull [group|all|list] — pull images listed in docker-images.txt
dpull() {
  local -a files=($DOTFILES_DIR/config/docker-images.txt(N) $XDG_CONFIG_HOME/dotfiles/docker-images.txt(N))
  local -a entries=(${(f)"$(cat $files 2>/dev/null | sed -e 's/#.*//' -e '/^[[:space:]]*$/d')"})
  local want=${1:-list} group image line
  if [[ $want == list ]]; then
    print "usage: dpull <group|all>"; print -l -- $entries; return
  fi
  for line in $entries; do
    group=${${(z)line}[1]} image=${${(z)line}[2]}
    [[ $want == all || $want == $group ]] && docker pull $image
  done
}
