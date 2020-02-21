require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.filter_sensitive_data('<TWITTER_CONSUMER_KEY>') { ENV['TWITTER_CONSUMER_KEY'] }
  config.filter_sensitive_data('<TWITTER_CONSUMER_SECRET>') { ENV['TWITTER_CONSUMER_SECRET'] }
  config.filter_sensitive_data('<TWITTER_OAUTH_TOKEN>') { ENV['TWITTER_OAUTH_TOKEN'] }
  config.filter_sensitive_data('<TWITTER_OAUTH_SECRET>') { ENV['TWITTER_OAUTH_SECRET'] }
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = true
end
