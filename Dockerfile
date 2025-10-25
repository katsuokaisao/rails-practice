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

# Install Ruby dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle config set path 'vendor/bundle' \
    && bundle install

# Install Node.js dependencies
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy application code
COPY . .

EXPOSE 3000

