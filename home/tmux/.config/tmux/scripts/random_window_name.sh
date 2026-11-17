#!/usr/bin/env bash
# Give a new tmux window a random character name.
# Each session sticks to one universe, picked at random from @name_themes
# (set by the installer, e.g. "harrypotter starwars marvel").
#   random_window_name.sh session|window <window_id>

harrypotter=(harry hermione ron dumbledore hagrid snape mcgonagall dobby neville
  draco voldemort ginny luna fred george cho cedric sirius remus tonks bellatrix
  lucius narcissa fleur kingsley seamus percy hedwig buckbeak crookshanks grawp
  trelawney quirrell lavender slughorn filch flitwick pomfrey aragog peeves
  moaningmyrtle kreacher grindelwald fawkes)
starwars=(luke leia han chewbacca yoda obiwan vader palpatine anakin padme r2d2
  c3po lando boba jango mace quigon maul dooku grievous ahsoka rey finn poe kylo
  bb8 jabba greedo wedge ackbar windu din grogu cassian jyn k2so thrawn hondo
  ventress rex cody sabine ezra kanan hera zeb chopper)
marvel=(ironman thor hulk loki widow hawkeye cap falcon wanda vision strange
  spidey panther shuri groot rocket gamora drax starlord nebula mantis thanos
  antman wasp marvel fury coulson hill wolverine storm cyclops jean magneto
  xavier deadpool venom daredevil punisher elektra jessica cage ironfist
  moonknight shangchi kang ultron hela valkyrie okoye wong)

win=${2:-$(tmux display -p "#{window_id}")}   # old hooks pass no id
# The universe comes from a hash of the session id + creation time, so every
# window of a session agrees on it without shared state (hooks can race).
read -ra themes <<<"$(tmux show-option -gqv @name_themes)"
(( ${#themes[@]} )) || themes=(harrypotter)
seed=$(tmux display -p -t "$win" '#{session_id}#{session_created}' | cksum | cut -d' ' -f1)
theme=${themes[seed % ${#themes[@]}]}
declare -n names=$theme 2>/dev/null || exit 0
(( ${#names[@]} )) || exit 0

used=" $(tmux list-windows -t "$win" -F '#W' | tr '\n' ' ') "
name=""
for _ in {1..100}; do
  n=${names[RANDOM % ${#names[@]}]}
  [[ $used != *" $n "* ]] && { name=$n; break; }
done
tmux rename-window -t "$win" "${name:-$theme}"
