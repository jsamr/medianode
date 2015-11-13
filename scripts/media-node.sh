#!/bin/bash
#Make path relative
cd "${BASH_SOURCE%/*}" || (echo "FAILURE: impossible de trouver le répertoire courant" && exit 1)
## executer le script avec le groupe 'media-node'
sg media-node -c "redis-server /etc/redis/redis.conf" &
redisPID=$!
echo "Redis lancé avec pid ${redisPID}"
sg media-node -c "coffee ../src/app.coffee"

