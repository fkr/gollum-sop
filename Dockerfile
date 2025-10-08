FROM ruby:3.2

RUN apt-get update && apt-get install -y \
    git \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Configure git to trust the wiki directory
RUN git config --global --add safe.directory /wiki

WORKDIR /app

COPY Gemfile /app/
RUN bundle install

EXPOSE 4567

CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "4567"]
