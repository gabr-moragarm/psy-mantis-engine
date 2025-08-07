#!/bin/sh
set -e

HOST=${HOST:-0.0.0.0}
PORT=${CONTAINER_PORT:-4567}
ENV=${RACK_ENV:-production}

echo "Starting app in $ENV mode on http://$HOST:$PORT"

exec bundle exec rackup --host "$HOST" --port "$PORT"