require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module OdieBackend
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.twitter_template = File.join(
      Rails.root, 'logstash', 'config', 'twitter_template.json'
    )
    # How many users to include in a data set.
    config.num_users = ( ENV['NUM_USERS'] || 5000 ).to_i

    # How many tweets to collect from each user during a data collection run.
    config.tweets_per_user = ( ENV['TWEETS_PER_USER'] || 50 ).to_i

    # Whatever invokes logstash in this environment.
    config.logstash_command = ENV['LOGSTASH_COMMAND'] || 'logstash'

    # How long to run logstash for. Can be any format accepted by `timeout`
    # (X, Xs, Xh, Xd for numerical values of X).
    config.logstash_run_time = ENV['LOGSTASH_RUN_TIME'] || '1h'

    # Where logstash config files live
    config.logstash_conf_dir = Rails.root.join('logstash', 'config')

    config.autoload_paths << Rails.root.join('lib')
    config.autoload_paths << Rails.root.join('app', 'models', 'extractors')

    config.log_level = :debug
  end
end
