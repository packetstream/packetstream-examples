FROM ruby:4.0-alpine

WORKDIR /app
COPY Gemfile Gemfile.lock ./
# Install the locked runtime gems only; RuboCop is a development dependency
ENV BUNDLE_FROZEN=true BUNDLE_WITHOUT=development
RUN bundle install
COPY main.rb .

USER nobody
CMD ["bundle", "exec", "ruby", "main.rb"]
