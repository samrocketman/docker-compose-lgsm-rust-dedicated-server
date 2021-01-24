#!/bin/bash

echo -n 'RCON password: '
docker-compose exec -T lgsm cat rcon_pass

echo '
Visit one of the following web RCON clients:

- http://facepunch.github.io/webrcon address 127.0.0.1:28016
- http://rcon.io/login address 127.0.0.1 port 28016
'
