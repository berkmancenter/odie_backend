[![Build Status](https://travis-ci.org/berkmancenter/odie_backend.svg?branch=master)](https://travis-ci.org/berkmancenter/odie_backend)
[![Coverage Status](https://coveralls.io/repos/github/berkmancenter/odie_backend/badge.svg?branch=master)](https://coveralls.io/github/berkmancenter/odie_backend?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/80c54b5a43b952542cdb/maintainability)](https://codeclimate.com/github/berkmancenter/odie_backend/maintainability)

# README

These instructions are for ODIE developers. You might instead want to read...
* [the admin docs](doc/admin.md), if you're an administrator of an ODIE instance
* [the api docs](doc/api.md), if you're writing code to consume the ODIE API.

# System requirements
* ruby 2.6
* postgres 9.2+.
* Elasticsearch 6.5
* Logstash 6.5

## Getting started
* Copy `config/database.yml.example` to `config/database.yml` and change its values to match your postgres.
* `bundle install`
* `rails db:setup`

## Environment Variables
Set all environment variables in `.env`.

In production:
* `DATABASE_USERNAME`
* `DATABASE_PASSWORD`
* `DATABASE_NAME`
* `DATABASE_HOST`
* `DATABASE_PORT` (optional; defaults to `5432`)
* `DATABASE_TIMEOUT` (optional; defaults to `5000`)
* `MAILER_SENDER`
* `DEFAULT_URL_OPTIONS_HOST` (defaults to `localhost`)
* `DEFAULT_URL_OPTIONS_PORT` (optional)
* `SECRET_KEY_BASE`

In production, or in dev if you want to write `twitter.conf` files, you will need:
* `TWITTER_CONSUMER_KEY`
* `TWITTER_CONSUMER_SECRET`
* `TWITTER_OAUTH_TOKEN`
* `TWITTER_OAUTH_SECRET`
* `ELASTICSEARCH_HOST`
* `ELASTICSEARCH_INDEX`

In any environment:
* `NUM_USERS` (optional; defaults to `5000`)
* `TWEETS_PER_USER` (optional; defaults to `50`)
* `LOGSTASH_COMMAND` (optional; whatever invokes logstash on your system; defaults to `logstash`)
* `LOGSTASH_RUN_TIME` (optional; how long to run the streaming data collection run; can be any duration accepted by `timeout`; defaults to `1h`)

In test:
* `TEST_CLUSTER_COMMAND` (the command which runs Elasticsearch on your machine)

## Collecting Twitter data
To test that your streaming data collection pipeline is running:
* Copy `twitter.conf.example` to `test.conf` and edit in the appropriate variables.
  * The keywords can be anything, but not all keywords will be found on Twitter within a short amount of time; "washingtonpost" is a reliable choice.
* Make sure elasticsearch is running.
* `logstash -f logstash/config/test.conf`
  - On the server, this is `/usr/share/logstash/bin/logstash -f logstash/config/test.conf`.

To collect user data:
* Make sure you have collected some streaming data.
* Make sure elasticsearch is running.
* Create a MediaSource, a DataConfig and a DataSet.
  - Good defaults:
    - `ms = MediaSource.create(url: 'https://www.washingtonpost.com', name: 'Washington Post', description: 'Democracy dies in darkness')`
    - `dc = DataConfig.create(media_sources: [ms])`
    - `ds = DataSet.create(media_source: ms, data_config: dc)`
* `ds.run_pipeline`

This will all be wrapped into an admin-friendly workflow at some point, but it hasn't been yet.

## Docker

You can use Docker for development to make things easier. You will need to install `Docker` and `Docker Compose`.

Then:
- copy `config/database.yml.example` to `config/database.yml` and change update the development section to `postgres` for the host, username, password and database
- `docker-compose exec website sh`
- `rails db:setup`
- `docker-compose up` and the application will run on http://localhost:3000

## Tests
Run tests with `rspec`.

Aim to adhere to http://www.betterspecs.org/.

Take inspiration from Sandi Metz's [Magic Tricks of Testing](https://www.youtube.com/watch?v=URSWYvyc42M): assert results and side effects of messages received from collaborators; assert that messages are sent to collaborators; don't test private methods or messages sent to self.

### Troubleshooting
If elasticsearch is timing out in tests, your elasticsearch process may be
failing to get a node lock. Kill any other Elasticsearch processes. (This is
especially likely if you have ended another test run early, without shutting
down the test cluster.)

## General development instructions
* Keep test coverage above 90%. (`open coverage/index.html` after a test run to see how you're doing.)
* Use a rubocop-based linter.
* Travis, Coveralls, and CodeClimate checks must all be passing before code is merged; `master` should always be deployable.
