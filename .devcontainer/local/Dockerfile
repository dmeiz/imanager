FROM ruby:3.3-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    default-libmysqlclient-dev \
    default-mysql-client \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Rails
RUN gem install rails -v '~> 7.1'

WORKDIR /workspaces/imanager
