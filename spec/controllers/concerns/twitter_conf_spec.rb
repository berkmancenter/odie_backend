require 'rails_helper'

describe TwitterConf do
  it 'validates presence of its REQUIRED_VARS' do
    context = binding
    TwitterConf::REQUIRED_VARS.each do |var|
      context.local_variable_set(var, 'foo')
    end
    expect(TwitterConf.valid? context).to be true

    context2 = binding
    expect(TwitterConf.valid? context2).to be false
  end

  it 'generates a template result' do
    cache_env
    context = binding
    context.local_variable_set(:keywords, 'foo')
    context.local_variable_set(:env, ENV)
    assert_equal EXPECTED_CONF, TwitterConf.generate(context)
  end

  def cache_env
    @cached = {}
    @cached['TWITTER_CONSUMER_KEY']     = ENV['TWITTER_CONSUMER_KEY']
    @cached['TWITTER_CONSUMER_SECRET']  = ENV['TWITTER_CONSUMER_SECRET']
    @cached['TWITTER_OAUTH_TOKEN']      = ENV['TWITTER_OAUTH_TOKEN']
    @cached['TWITTER_OAUTH_SECRET']     = ENV['TWITTER_OAUTH_SECRET']
    @cached['ELASTICSEARCH_HOST']       = ENV['ELASTICSEARCH_HOST']
    @cached['ELASTICSEARCH_INDEX']      = ENV['ELASTICSEARCH_INDEX']

    ENV['TWITTER_CONSUMER_KEY']     = 'key'
    ENV['TWITTER_CONSUMER_SECRET']  = 'secret'
    ENV['TWITTER_OAUTH_TOKEN']      = 'token'
    ENV['TWITTER_OAUTH_SECRET']     = 'secret2'
    ENV['ELASTICSEARCH_HOST']       = 'host'
    ENV['ELASTICSEARCH_INDEX']      = 'index'
  end

  def uncache_env
    @cached.each do |k, v|
      ENV[k] = v
    end
  end

  EXPECTED_CONF = <<EOF
  input {
    twitter {
        consumer_key => "key"
        consumer_secret => "secret"
        oauth_token => "token"
        oauth_token_secret => "secret2"
        keywords => foo
        full_tweet => true
    }
  }

  output {
    stdout { }
    elasticsearch {
        hosts         => host
        index         => "index"
        document_type => "_doc"
        template      => "#{Rails.application.config.twitter_template}"
        template_name => "odie"
        template_overwrite => true
    }
  }
EOF
end
