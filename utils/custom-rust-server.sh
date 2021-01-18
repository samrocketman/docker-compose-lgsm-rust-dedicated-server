#!/bin/bash

# DESCRIPTION:
#   Dedicated server LGSM startup script which initializes some security best
#   practices for Rust.

set -ex

[ ! -r /rust-environment.sh ] || source /rust-environment.sh

export ENABLE_RUST_EAC

function rand_password() {
  tr -dc -- '0-9a-zA-Z' < /dev/urandom | head -c12;echo
}

[ -f ./linuxgsm.sh ] || cp /linuxgsm.sh ./
[ -x ./rustserver ] || ./linuxgsm.sh rustserver
yes Y | ./rustserver install
[ -f ./lgsm/mods/rustoxide-files.txt ] || ./rustserver mods-install <<< $'rustoxide\n'
./rustserver mods-update

# disable EAC allowing Linux clients
server_cfg=serverfiles/server/rustserver/cfg/server.cfg
if [ -z "${ENABLE_RUST_EAC:-}" ]; then
  grep -F -- server.secure "$server_cfg" || echo server.secure 0 >> "$server_cfg"
  grep -F -- server.encryption "$server_cfg" || echo server.encryption 0 >> "$server_cfg"
else
  sed -i '/^ *server\.secure/d' "$server_cfg"
  sed -i '/^ *server\.encryption/d' "$server_cfg"
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
  grep rconpassword lgsm/config-lgsm/rustserver/rustserver.cfg || echo rconpassword="$(<rcon_pass)" >> lgsm/config-lgsm/rustserver/rustserver.cfg
) &> /dev/null

# remove passwordless sudo access since setup is complete
sudo rm -f /etc/sudoers.d/lgsm

/get-or-update-plugins.sh

# start rust server
./rustserver start
echo Sleeping for 30 seconds...
sleep 30
tail -f log/*/*.log
