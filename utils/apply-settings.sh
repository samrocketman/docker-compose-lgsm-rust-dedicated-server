#!/bin/bash

set -ex

[ ! -r /rust-environment.sh ] || source /rust-environment.sh
server_cfg=serverfiles/server/rustserver/cfg/server.cfg
lgsm_cfg=lgsm/config-lgsm/rustserver/rustserver.cfg

# disable EAC allowing Linux clients
if [ -z "${ENABLE_RUST_EAC:-}" ]; then
  grep -F -- server.secure "$server_cfg" || echo server.secure 0 >> "$server_cfg"
  grep -F -- server.encryption "$server_cfg" || echo server.encryption 0 >> "$server_cfg"
else
  sed -i '/^ *server\.secure/d' "$server_cfg"
  sed -i '/^ *server\.encryption/d' "$server_cfg"
fi

# Map generation settings
function check-range() {
# Usage: check-range NUMBER MIN MAX
# exits nonzero if outside of range or not a number
python -c "
import sys;
i=int(sys.stdin.read());
exit(0) if i >= $2 and i <= $3 else exit(1)" &> /dev/null <<< "$1"
}
function apply-setting() {
  sed -i "/^ *$2/d" $1
  echo "$3" >> "$1"
}
if ( [ -z "$seed" ] || ! check-range "${seed:-invalid}" 1 2147483647 ) &&
   ! grep -F -- 'seed=' "$lgsm_cfg"; then
  # random seed; if seed is unset or invalid
  seed="$(python -c 'from random import randrange;print(randrange(2147483647))')"
fi


if [ -z "$worldsize" ] || ! check-range "$worldsize" 1000 6000; then
  worldsize=3000
fi
if [ -z "$maxplayers" ] || ! check-range "$maxplayers" 1 1000000; then
  maxplayers=50
fi
servername="${servername:-Rust}"
# apply user-customized settings from rust-environment.sh
if [ -n "$seed" ]; then
  apply-setting "$lgsm_cfg" seed "seed=$seed"
fi
apply-setting "$lgsm_cfg" worldsize "worldsize=$worldsize"
apply-setting "$lgsm_cfg" maxplayers "maxplayers=$maxplayers"
apply-setting "$lgsm_cfg" servername "servername=\"$servername\""
if [ -n "$salt" ]; then
  apply-setting "$lgsm_cfg" salt "salt=$salt"
else
  sed -i '/^ *salt/d' "$lgsm_cfg"
fi

# Custom Map Support
function start_custom_map_server() (
  cd /custom-maps/
  python -m SimpleHTTPServer &
)
function get_custom_map_url() {
  local base_url=http://localhost:8000/
  until curl -sIfLo /dev/null "$base_url"; do sleep 1; done
  local map_url="$(curl -sfL "$base_url" | grep -o 'href="[^"]\+.map"' | sed 's/.*"\([^"]\+\)"/\1/' | head -n1)"
  echo "${base_url}${map_url}"
}
if ls -1 /custom-maps/*.map &> /dev/null; then
  # custom map found so disabling map settings.
  start_custom_map_server
  export CUSTOM_MAP_URL="$(get_custom_map_url)"
fi

if [ ! -f rcon_pass ]; then
  rand_password > rcon_pass
fi
(
  grep rconpassword "$lgsm_cfg" || echo rconpassword="$(<rcon_pass)" >> "$lgsm_cfg"
) &> /dev/null
