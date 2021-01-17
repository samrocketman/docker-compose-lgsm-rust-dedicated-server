#!/bin/bash
# DESCRIPTION:
#   Install, remove, and upgrade Oxide plugins from the Rust dedicated server.
#   Supports logging into the server.

set -e
plugin_dir=/home/linuxgsm/serverfiles/oxide/plugins
plugin_txt=/home/linuxgsm/serverfiles/oxide/config/plugins.txt
if [ ! -f "$plugin_txt" ];  then
  plugin_txt=/dev/null
fi

# state variables
custom_plugins=()
upgraded_plugins=()
added_plugins=()
removed_plugins=()

function hash_stdin() {
  sha256sum
}

#
# Check for plugin updates
#
function upgrade_plugins() {
  local plugin_name
  while read plugin; do
    if [ -z "$plugin" ]; then
      continue
    fi
    local_hash=$(hash_stdin < "${plugin}")
    remote_hash="$(curl -sfL https://umod.org/plugins/"${plugin##*/}" | hash_stdin)"
    if  [ !  "$local_hash" = "$remote_hash" ]; then
      if curl -sIfLo /dev/null https://umod.org/plugins/"${plugin##*/}" && \
         curl -sfL https://umod.org/plugins/"${plugin##*/}" > "$plugin"; then
        plugin_name="${plugin##*/}"
        plugin_name="${plugin_name%.cs}"
        upgraded_plugins+=( "$plugin_name" )
      fi
    fi
  done <<< "$(find "$plugin_dir" -type f -name '*.cs')"
}

#
# Add new plugins
#
function add_new_plugins() {
  while read plugin; do
    if [ -z "$plugin" ] || [ -f "$plugin_dir"/"$plugin".cs ]; then
      continue
    fi
    if [ ! -f "${plugin_dir}/${plugin}.cs" ]; then
      if curl -sIfLo /dev/null https://umod.org/plugins/"${plugin}".cs && \
         curl -sfL https://umod.org/plugins/"${plugin}".cs > "${plugin_dir}/${plugin}".cs; then
        added_plugins+=( "${plugin}" )
      fi
    fi
  done <<< "$(grep -v '^ *$\|^ *#' "$plugin_txt")"
}

#
# Remove old plugins
#
function remove_plugins() {
  while read plugin; do
    if [ -z "$plugin" ]; then
      continue
    fi
    plugin_name="${plugin##*/}"
    plugin_name="${plugin_name%.cs}"
    if ! curl -sIfLo /dev/null https://umod.org/plugins/"${plugin_name}".cs; then
      custom_plugins+=( "${plugin_name}")
      continue
    fi
    if ! grep -v '^ *$\|^ *#' "$plugin_txt" | grep "${plugin_name}" > /dev/null; then
      rm -f "${plugin}"
      removed_plugins+=( "$plugin_name" )
    fi
  done <<< "$(find "$plugin_dir" -type f -name '*.cs')"
}

upgrade_plugins
add_new_plugins
remove_plugins

if [ "${#upgraded_plugins[@]}" -gt 0 ]; then
  echo 'Upgraded plugins:'
  for x in "${upgraded_plugins[@]}"; do
    echo "    $x"
  done
else
  echo 'No plugins upgraded.'
fi
if [ "${#added_plugins[@]}" -gt 0 ]; then
  echo 'New plugins installed:'
  for x in "${added_plugins[@]}"; do
    echo "    $x"
  done
else
  echo 'No new plugins.'
fi
if [ "${#removed_plugins[@]}" -gt 0 ]; then
  echo 'Plugins deleted:'
  for x in "${removed_plugins[@]}"; do
    echo "    $x"
  done
else
  echo 'No plugins deleted.'
fi
if [ "${#custom_plugins[@]}" -gt 0 ]; then
  echo 'The following custom plugins were ignored:'
  for x in "${custom_plugins[@]}"; do
    echo "    $x"
  done
else
  echo 'No custom plugins found.'
fi
