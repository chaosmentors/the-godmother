FROM ruby:3.3.9-alpine3.22 AS base
RUN apk add --no-cache postgresql-client nodejs vim build-base postgresql-dev tzdata yaml-dev

# Install specific Bundler version to match Gemfile.lock
RUN gem install bundler -v 2.7.2

RUN mkdir /app
WORKDIR /app

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

EXPOSE 3000

FROM base AS development

ENV RAILS_ENV=development

ENTRYPOINT ["entrypoint.sh"]

# Start the main process.
CMD ["bin/dev"]

FROM base AS production

ENV RAILS_ENV=production

COPY . /app

RUN bundle install
RUN SECRET_KEY_BASE=dummy bundle exec rake assets:precompile

# Start the main process.
CMD ["rails", "server", "-e", "production", "-b", "0.0.0.0"]