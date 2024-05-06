#!/bin/bash

docker exec -itu "${1:-linuxgsm}" $(docker compose ps -q lgsm) /bin/bash
