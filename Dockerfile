FROM ruby:3.3.6-slim AS build

RUN apt-get update -qq && apt-get install -y \
  build-essential libpq-dev nodejs curl git

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3 \
  --path /usr/local/bundle

COPY . .

FROM ruby:3.3.6-slim AS runtime

RUN apt-get update -qq && apt-get install -y \
  libpq-dev

WORKDIR /app

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
