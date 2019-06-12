[![Build Status](https://travis-ci.org/berkmancenter/odie_backend.svg?branch=master)](https://travis-ci.org/berkmancenter/odie_backend)
[![Coverage Status](https://coveralls.io/repos/github/berkmancenter/odie_backend/badge.svg?branch=master)](https://coveralls.io/github/berkmancenter/odie_backend?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/80c54b5a43b952542cdb/maintainability)](https://codeclimate.com/github/berkmancenter/odie_backend/maintainability)

# README

The ODIE API requires ruby 2.6 and postgres.

## Getting started
* Copy `config/database.yml.example` to `config/database.yml` and change its values to match your postgres.
* `bundle install`
* `rails db:setup`

## Environment Variables
For production, set:
* `DATABASE_USERNAME`
* `DATABASE_PASSWORD`
* `DATABASE_NAME`
* `DATABASE_HOST`
* `DATABASE_PORT` (optional; defaults to `5432`)
* `DATABASE_TIMEOUT` (optional; defaults to `5000`)
* `MAILER_SENDER`
* `DEFAULT_URL_OPTIONS_HOST` (defaults to `localhost`)
* `DEFAULT_URL_OPTIONS_PORT` (optional)

In production, or in dev if you want to write `twitter.conf` files, you will need:
* `TWITTER_CONSUMER_KEY`
* `TWITTER_CONSUMER_SECRET`
* `TWITTER_OAUTH_TOKEN`
* `TWITTER_OAUTH_SECRET`
* `ELASTICSEARCH_HOST`
* `ELASTICSEARCH_INDEX`

For any environment:
* `NUM_USERS` (optional; defaults to `5000`)
* `TWEETS_PER_USER` (optional; defaults to `50`)

## Tests
Run tests with `rspec`.

Aim to adhere to http://www.betterspecs.org/.

Take inspiration from Sandi Metz's [Magic Tricks of Testing](https://www.youtube.com/watch?v=URSWYvyc42M): assert results and side effects of messages received from collaborators; assert that messages are sent to collaborators; don't test private methods or messages sent to self.

## General development instructions
* Keep test coverage above 90%. (`open coverage/index.html` after a test run to see how you're doing.)
* Use a rubocop-based linter.
* Travis, Coveralls, and CodeClimate checks must all be passing before code is merged; `master` should always be deployable.
