FROM ruby:2.6.3-alpine

RUN apk update && apk add build-base nodejs postgresql-dev tzdata git

RUN mkdir /app
WORKDIR /app

COPY . .
RUN bundle install

CMD puma -C config/puma.rb
