#!/bin/sh
set -e

./swarm-cron crontab

exec "$@"
