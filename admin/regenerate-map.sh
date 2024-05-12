#!/bin/bash

# set the working directory to repository root
# only when this script is called by full path; e.g. from cron job
if grep '^/' <<<  "$0" > /dev/null; then
  echo "Changing working directory to: ${0%admin/*}"
  cd "${0%admin/*}"
fi

if [ -n "${1:-}" ]; then
  echo 'Skipping user prompt.'
else
  cat <<'EOF'
WARNING: This is a permanent action.
All maps will be destroyed including backups and a new map will be generated.
EOF
  read -erp 'Do you wish to delete the current map? (y/N) ' response

  if [ ! "$response" = y -a ! "$response" = Y ]; then
    echo 'Operation aborted.  Respond "y" next time if you want to proceed.'
    exit
  fi
fi

docker compose exec -T lgsm \
  find serverfiles/server/rustserver/ \
    -maxdepth 1 \
    -type f \( -name '*.map' -o -name '*.sav*' \) \
    -exec rm -f {} +
docker compose exec -T lgsm sed -i '/^ *seed=/d' lgsm/config-lgsm/rustserver/rustserver.cfg
docker compose down
docker compose up -d
echo 'The server has been rebooted with docker compose up -d.'
