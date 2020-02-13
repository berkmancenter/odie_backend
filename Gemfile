source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.3'

# Use bleeding-edge administrate because the rubygems version still uses
# ruby-sass (which is deprecated) and we're on sassc-rails.
gem 'administrate', git: 'https://github.com/thoughtbot/administrate'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'coffee-rails', '~> 4.2'
gem 'devise'
gem 'dotenv-rails'
gem 'elasticsearch', '~>6.0'
# Required for Elasticsearch compat even though not specified in their gemspec.
gem 'faraday', '~>0.15.0'
gem 'fast_jsonapi'
gem 'rails', '~> 5.2.3'
gem 'pg'
gem 'puma', '~> 3.11'
gem 'sassc-rails'
gem 'stopwords-filter', require: 'stopwords'
gem 'therubyracer'
gem 'turbolinks', '~> 5'
gem 'twitter'
gem 'uglifier', '>= 1.3.0'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'annotate'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'coveralls', require: false
  gem 'capybara', '>= 2.15'
  gem 'elasticsearch-extensions'
  gem 'factory_bot_rails'
  gem 'rspec-rails'
  gem 'simplecov', require: false
  gem 'vcr'
  gem 'webdrivers'
  gem 'webmock'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
