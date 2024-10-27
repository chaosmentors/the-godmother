FROM ruby:3.3.5 AS base
RUN apt-get update -qq && apt-get install -y postgresql-client nodejs vim

RUN mkdir /myapp
WORKDIR /myapp
COPY . /myapp

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

EXPOSE 3000

FROM base AS development
RUN bundle install

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# Start the main process.
CMD ["rails", "server", "-b", "0.0.0.0"]

FROM base AS production

RUN bundle install --without development test
RUN RAILS_ENV=production bundle exec rake assets:precompile

# Start the main process.
CMD ["rails", "server", "-e", "production", "-b", "0.0.0.0"]