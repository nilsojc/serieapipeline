#!/bin/sh
set -e

# Start Docker daemon in the background
dockerd &

# Wait for Docker daemon to start
sleep 5

# Execute the command passed to the container
exec "$@"