FROM ruby:3.3.7

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential default-mysql-client git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle config set path 'vendor/bundle' \
    && bundle install

COPY . .
EXPOSE 3000
