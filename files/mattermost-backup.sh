#!/bin/bash
docker_compose="docker compose -f docker-compose.yml -f docker-compose.without-nginx.yml"
mm_dir="/var/lib/mattermost"
set -e

cd $mm_dir
${docker_compose} --progress quiet stop
rsync -aH --delete ${mm_dir}/volumes/db/ ${mm_dir}/volumes/db-backup/
${docker_compose} --progress quiet -p mattermost up -d --quiet-pull
