# Dockerfile
FROM ruby:3.3

# Install dependencies
RUN apt-get update -qq \
  && apt-get install -y --no-install-recommends build-essential \
  && rm -rf /var/lib/apt/lists/*

# Set working dir
WORKDIR /app

# Copy and install gems
COPY Gemfile* ./
RUN bundle install

# Copy rest of the app
COPY . .
RUN chmod +x ./entrypoint.sh

# Start the app
CMD ["./entrypoint.sh"]