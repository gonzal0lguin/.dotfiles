#!/usr/bin/env bash
# Values for the tmux "stats" status bar: stats.sh cpu|ram|gpu|ip
case ${1:-} in
  cpu)
    # usage since the previous call, from /proc/stat (no `top` needed)
    read -r _ u n s i w x y z _ </proc/stat
    total=$((u + n + s + i + w + x + y + z)) idle=$((i + w))
    f=${XDG_RUNTIME_DIR:-/tmp}/tmux-cpu-$UID
    pct=0
    if [[ -r $f ]]; then
      read -r pt pi <"$f"
      dt=$((total - pt)) di=$((idle - pi))
      ((dt > 0)) && pct=$(((100 * (dt - di)) / dt))
    fi
    echo "$total $idle" >"$f"
    printf '%d%%' "$pct"
    ;;
  ram)
    free -m | awk '/^Mem:/ {printf "%.1fG", $3/1024}'
    ;;
  gpu)
    # prints a whole segment, or nothing when there is no NVIDIA GPU
    command -v nvidia-smi >/dev/null || exit 0
    out=$(nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv,noheader,nounits 2>/dev/null | head -1) || exit 0
    [[ -n $out ]] || exit 0
    IFS=', ' read -r util mem <<<"$out"
    printf '#[fg=black,bg=blue] 󰢮 %s%% %.1fG ' "$util" "$(awk "BEGIN{print $mem/1024}")"
    ;;
  ip)
    ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i=1;i<NF;i++) if ($i=="src") {print $(i+1); exit}}' || hostname -I | awk '{print $1}'
    ;;
  *) echo "usage: $0 cpu|ram|gpu|ip" >&2; exit 1 ;;
esac
