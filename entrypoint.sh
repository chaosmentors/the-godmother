#!/bin/sh
set -e

# Bundle install for development environment
if [ "$RAILS_ENV" = "development" ]; then
  bundle check || bundle install
fi

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# Check for pending migrations
if ! bundle exec rails db:abort_if_pending_migrations; then
  bundle exec rails db:migrate
fi

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
