#!/bin/bash
# DESCRIPTION:
#   Install, remove, and upgrade Oxide plugins from the Rust dedicated server.
#   Supports logging into the server.

set -e
plugin_dir=/home/linuxgsm/serverfiles/oxide/plugins
plugin_txt=/home/linuxgsm/serverfiles/oxide/config/plugins.txt
export TMP_DIR="$(mktemp -d)"
trap '[ ! -d "$TMP_DIR" ] || rm -rf "$TMP_DIR"' EXIT
if [ ! -f "$plugin_txt" ];  then
  plugin_txt=/dev/null
fi
if [ ! -d "$plugin_dir" ]; then
  mkdir -p "$plugin_dir"
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
function get_plugin_name_by_class() {
  awk '
  $0 ~ /namespace/ {nextclass=1};
  nextclass == 1 && $0 ~ /class [a-zA-Z]+/ {
    for(i=1; i<NF+1; i++) {
      if($i == "class") {
        c=i
        break
      }
    };
    print $(c+1);
    exit
  }
  '
}
function upgrade_plugins() {
  local plugin_name
  while read plugin; do
    if [ -z "$plugin" ] || [ -f "${plugin##*/}" ]; then
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
function add_new_plugins() {
  retry_limit=5
  retry_delay=5
  while IFS= read -r plugin || [[ -n "$plugin" ]]; do
    # Trim leading/trailing whitespace and remove any special characters that might break the URL
    plugin=$(echo "$plugin" | xargs | sed 's/[^a-zA-Z0-9_-]//g')
    found_plugin="$(find "$plugin_dir" -type f -iname "${plugin}.cs")"
    if [ -z "$plugin" ] || [ -n "${found_plugin}" ]; then
      continue
    fi

    echo "Checking plugin: $plugin"
    function download_plugin() {
      local retries=0
      local success=false
      while [ $retries -lt $retry_limit ]; do
        http_status=$(curl -sI -w "%{http_code}" -o /dev/null "https://umod.org/plugins/${plugin}.cs")
        if [ "$http_status" -eq 200 ]; then
          if curl -sSfLo "${TMP_DIR}/${plugin}.cs" "https://umod.org/plugins/${plugin}.cs" && \
              plugin_name="$(get_plugin_name_by_class < "${TMP_DIR}/${plugin}.cs")" && \
              mv "${TMP_DIR}/${plugin}.cs" "${plugin_dir}/${plugin_name}.cs"; then
            added_plugins+=( "$plugin_name" )
            echo "Successfully added plugin: $plugin_name"
            success=true
            break
          else
            echo "Error: Failed to download plugin: $plugin" >&2
            break
          fi
        elif [ "$http_status" -eq 429 ]; then
          # Rate limit encountered
          echo "Rate limit reached. Waiting for $retry_delay seconds before retrying..." >&2
          sleep $retry_delay
          retries=$((retries + 1))
          retry_delay=$((retry_delay * 2))  # Exponential backoff
        else
          echo "Error: Plugin $plugin not found on the server or could not connect (HTTP $http_status)." >&2
          break
        fi
      done

      if [ "$success" = false ]; then
        echo "Failed to add plugin: $plugin after $retries retries." >&2
      fi
    }

    download_plugin

  done <<< "$(grep -v '^ *$\|^ *#' "$plugin_txt")"
  if [ "${#added_plugins[@]}" -gt 0 ]; then
    echo "The following plugins were added successfully: ${added_plugins[*]}"
  else
    echo "No new plugins were added."
  fi
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
    if ! grep -v '^ *$\|^ *#' "$plugin_txt" | grep -i "${plugin_name}" > /dev/null &&
       [ ! -f "/custom-plugins/${plugin_name}.cs" ]; then
      rm -f "${plugin}"
      removed_plugins+=( "$plugin_name" )
    fi
  done <<< "$(find "$plugin_dir" -type f -name '*.cs')"
}

function copy_custom_plugins() {
  if ls /custom-plugins/*.cs &> /dev/null; then
    rsync -a /custom-plugins/*.cs "${plugin_dir}/"
  fi
}

copy_custom_plugins
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

if ls /custom-plugins/*.cs &> /dev/null; then
  echo 'Custom plugins:'
  (
    cd /custom-plugins/
    ls -1 *.cs | sed 's/\(.*\)\.cs/    \1/'
  )
  for x in "${custom_plugins[@]}"; do
    echo "    $x"
  done
else
  echo 'No custom plugins found.'
fi
