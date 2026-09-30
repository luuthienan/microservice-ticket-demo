FROM ruby:3.4.9

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
