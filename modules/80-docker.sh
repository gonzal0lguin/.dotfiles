# shellcheck shell=bash
module docker on "Docker Engine (official repo), NVIDIA toolkit, lazydocker, dive, log rotation"

docker_configure() {
  DOCKER_PULL=$(choose "Pre-pull Docker images? (later: dpull <group>)" "${DOCKER_PULL:-none}" \
    none "Don't pull anything now" \
    ros "ros:jazzy, osrf/ros:jazzy-desktop" \
    base "ubuntu:24.04, ubuntu:22.04" \
    ml "nvidia/cuda base, python" \
    all "Everything in config/docker-images.txt")
  export DOCKER_PULL
}

_docker_engine() {
  if has docker && docker compose version >/dev/null 2>&1; then
    ok "docker $(docker --version | awk '{print $3}' | tr -d ,) + compose already installed"; return 0
  fi
  if pkg_installed docker.io; then
    warn "Ubuntu's docker.io is installed; it conflicts with Docker's packages"
    manual "Replace docker.io with Docker CE: sudo apt remove docker.io docker-compose && dot install docker"
    return 0
  fi
  local distro=ubuntu; [[ $OS_ID == debian ]] && distro=debian
  info "adding Docker's apt repository"
  run $SUDO install -m 0755 -d /etc/apt/keyrings
  run $SUDO curl -fsSL "https://download.docker.com/linux/$distro/gpg" -o /etc/apt/keyrings/docker.asc
  run $SUDO chmod a+r /etc/apt/keyrings/docker.asc
  if (( ! DRY_RUN )); then
    printf 'Types: deb\nURIs: https://download.docker.com/linux/%s\nSuites: %s\nComponents: stable\nSigned-By: /etc/apt/keyrings/docker.asc\n' \
      "$distro" "$OS_CODENAME" | $SUDO tee /etc/apt/sources.list.d/docker.sources >/dev/null
  fi
  _APT_UPDATED=0
  apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

_docker_nvidia() {
  has nvidia-smi || return 0
  if ! has nvidia-ctk; then
    info "adding NVIDIA container toolkit repository"
    if (( ! DRY_RUN )); then
      curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey |
        $SUDO gpg --dearmor --yes -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
      curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list |
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' |
        $SUDO tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null
    fi
    _APT_UPDATED=0
    apt_install nvidia-container-toolkit
  fi
  if ! grep -q '"nvidia"' /etc/docker/daemon.json 2>/dev/null; then
    run $SUDO nvidia-ctk runtime configure --runtime=docker
    DOCKER_NEEDS_RESTART=1
  else
    ok "nvidia runtime already configured"
  fi
}

# Add log rotation to /etc/docker/daemon.json, keeping everything else.
_docker_daemon_json() {
  local f=/etc/docker/daemon.json cur new
  cur=$($SUDO cat "$f" 2>/dev/null || echo '{}')
  new=$(jq '."log-driver" = (."log-driver" // "json-file")
            | ."log-opts" = ({"max-size": "10m", "max-file": "3"} + (."log-opts" // {}))' <<<"$cur") || {
    warn "$f is not valid JSON; leaving it alone"; return 0; }
  if [[ $(jq -S . <<<"$cur") == "$(jq -S . <<<"$new")" ]]; then
    ok "daemon.json already has log rotation"; return 0
  fi
  if (( DRY_RUN )); then info "[dry-run] write log rotation to $f"; return 0; fi
  $SUDO mkdir -p /etc/docker
  printf '%s\n' "$new" | $SUDO tee "$f" >/dev/null
  ok "daemon.json: container logs capped at 3 x 10MB (new containers)"
  DOCKER_NEEDS_RESTART=1
}

docker_install() {
  DOCKER_NEEDS_RESTART=0
  if (( NO_PACKAGES )); then
    info "skipping engine/toolkit/daemon.json (--no-packages)"
  else
    _docker_engine
    _docker_nvidia
    _docker_daemon_json
    if ! id -nG "$USER" | grep -qw docker; then
      run $SUDO usermod -aG docker "$USER"
      manual "Log out and back in to use docker without sudo (you were added to the 'docker' group)"
    fi
    if (( DOCKER_NEEDS_RESTART )); then
      if [[ -z $(docker ps -q 2>/dev/null) ]]; then
        run $SUDO systemctl restart docker && ok "docker restarted"
      else
        manual "Restart docker when your containers can stop: sudo systemctl restart docker"
      fi
    fi
  fi

  local tag
  if ! has lazydocker && tag=$(gh_latest_tag jesseduffield/lazydocker); then
    install_release_bin lazydocker \
      "https://github.com/jesseduffield/lazydocker/releases/download/${tag}/lazydocker_${tag#v}_Linux_$(arch_name).tar.gz"
  fi
  if ! has dive && tag=$(gh_latest_tag wagoodman/dive); then
    install_release_bin dive \
      "https://github.com/wagoodman/dive/releases/download/${tag}/dive_${tag#v}_linux_$(arch_name amd64).tar.gz"
  fi

  local pull=${DOCKER_PULL:-none} group image
  if [[ $pull != none ]] && (( ! DRY_RUN )); then
    if docker info >/dev/null 2>&1; then
      while read -r group image; do
        [[ -z $group || $group == \#* ]] && continue
        [[ $pull == all || $pull == "$group" ]] && { info "docker pull $image"; docker pull -q "$image" || warn "pull failed: $image"; }
      done <"$DOTFILES_DIR/config/docker-images.txt"
    else
      manual "Pull images after re-login: dpull $pull"
    fi
  fi
  return 0
}
