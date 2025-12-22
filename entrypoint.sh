#!/bin/sh
set -e

if [ "$RAILS_ENV" = "development" ]; then
  # Bundle install for development environment
  bundle check || bundle install

  # Remove a potentially pre-existing assets
  rm -rf /app/public/assets
fi

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# Create database only if it doesn't exist, then run migrations if needed
if ! bundle exec rails db:abort_if_pending_migrations 2>/dev/null; then
  bundle exec rails db:create 2>/dev/null || true
  bundle exec rails db:migrate
fi

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
