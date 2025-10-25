FROM ruby:3.3.7

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential \
    default-mysql-client \
    curl \
    git \
    ca-certificates \
    gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs graphviz \
    && corepack enable \
    && corepack prepare yarn@1.22.22 --activate \
    && yarn global add esbuild \
    && rm -rf /var/lib/apt/lists/*

RUN npx --yes playwright@latest install --with-deps chromium

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle config set path 'vendor/bundle' \
    && bundle install

COPY . .

# Add entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["bin/dev"]
