FROM ruby:3.3.5 AS base
RUN apt-get update -qq && apt-get install -y postgresql-client nodejs vim

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
CMD ["rails", "server", "-b", "0.0.0.0"]

FROM base AS production

ENV RAILS_ENV=production

COPY . /app

RUN bundle install
RUN SECRET_KEY_BASE=dummy bundle exec rake assets:precompile

# Start the main process.
CMD ["rails", "server", "-e", "production", "-b", "0.0.0.0"]