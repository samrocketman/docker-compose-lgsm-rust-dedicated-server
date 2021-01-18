#!/bin/bash

cat <<'EOF'
WARNING: This is a permanent action.
All maps will be destroyed including backups and a new map will be generated.
EOF
read -erp 'Do you wish to delete the current map? (y/N) ' response

if [ ! "$response" = y -a ! "$response" = Y ]; then
  echo 'Operation aborted.  Respond "y" next time if you want to proceed.'
  exit
fi

docker-compose exec -T lgsm \
  find serverfiles/server/rustserver/ \
    -maxdepth 1 \
    -type f \( -name '*.map' -o -name '*.sav*' \) \
    -exec rm -f {} +
docker-compose down
docker-compose up -d
echo 'The server has been rebooted with docker-compose up -d.'
