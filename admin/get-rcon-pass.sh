#!/bin/bash

echo -n 'RCON password: '
docker-compose exec -T lgsm cat rcon_pass

echo '
Visit http://facepunch.github.io/webrcon and connect to 127.0.0.1:28016 with
this password.'
