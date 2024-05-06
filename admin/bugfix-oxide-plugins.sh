#!/bin/bash

docker compose exec -T lgsm /bin/bash -ec 'unix2dos serverfiles/oxide/plugins/*.cs'
