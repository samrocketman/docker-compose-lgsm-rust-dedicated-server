#!/bin/bash

set -ex

[ ! -r /rust-environment.sh ] || source /rust-environment.sh
export ENABLE_RUST_EAC CUSTOM_MAP_URL MAP_BASE_URL SELF_HOST_CUSTOM_MAP
export seed salt worldsize maxplayers servername
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

function rand_password() {
  tr -dc -- '0-9a-zA-Z' < /dev/urandom | head -c12;echo
}

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
  MAP_BASE_URL="${MAP_BASE_URL:-http://localhost:8000/}"
  until curl -sIfLo /dev/null "http://localhost:8000/"; do sleep 1; done
  local map_url="$(curl -sfL "http://localhost:8000/" | grep -o 'href="[^"]\+.map"' | sed 's/.*"\([^"]\+\)"/\1/' | head -n1)"
  echo "${MAP_BASE_URL%/}/${map_url}"
}
function unquote-url() {
  python3 -c 'from urllib.parse import unquote;import sys;print(unquote(sys.stdin.read()).strip())'
}
function download-custom-map() {
  local custom_map="$(echo "${CUSTOM_MAP_URL}" | grep -o '[^/]\+\.map' | unquote-url)"
  if [ -z "${custom_map:-}" ]; then
    custom_map='custom-map.map'
  fi
  [ -f /custom-maps/"${custom_map}" ] || curl -fLo /custom-maps/"${custom_map}" "${CUSTOM_MAP_URL}"
}
sed -i '/^fn_parms/d' "$lgsm_cfg"


if [ -n "${CUSTOM_MAP_URL:-}" ] || ls -1 /custom-maps/*.map &> /dev/null; then
  if [ -n "${CUSTOM_MAP_URL:-}" -a "${SELF_HOST_CUSTOM_MAP:-}" = true ]; then
    download-custom-map
    unset CUSTOM_MAP_URL
  fi
  start_custom_map_server
  if [ -z "${CUSTOM_MAP_URL:-}" ]; then
    export CUSTOM_MAP_URL="$(get_custom_map_url)"
  fi
  # custom map found so disabling map settings.
  cat >> "$lgsm_cfg" <<EOF
fn_parms(){ parms="-batchmode +app.listenip \${ip} +app.port \${appport} +server.ip \${ip} +server.port \${port} +server.tickrate \${tickrate} +server.hostname \"\${servername}\" +server.identity \"\${selfname}\" +server.maxplayers \${maxplayers} +levelurl '${CUSTOM_MAP_URL}' +server.saveinterval \${saveinterval} +rcon.web \${rconweb} +rcon.ip \${ip} +rcon.port \${rconport} +rcon.password \"\${rconpassword}\" -logfile"; }
EOF
fi

if [ ! -f rcon_pass ]; then
  rand_password > rcon_pass
fi
(
  grep "$(<rcon_pass)" "$lgsm_cfg" || echo rconpassword="$(<rcon_pass)" >> "$lgsm_cfg"
) &> /dev/null
