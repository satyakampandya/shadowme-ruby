FROM ruby:3.4-slim

# Install system packages required for compiling gems with native extensions (Puma, Oj)
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy dependency definitions
COPY Gemfile Gemfile.lock ./

# Install dependencies
RUN gem install bundler && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Expose Puma's default port
EXPOSE 9292

# Start the application using Puma
CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:9292", "config.ru"]
