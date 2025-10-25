#!/bin/sh
set -e

# Remove server.pid if it exists
rm -f /app/tmp/pids/server.pid

# Install Node.js dependencies
echo "Installing Node.js dependencies..."
yarn install --frozen-lockfile

# Execute the main command
exec "$@"
