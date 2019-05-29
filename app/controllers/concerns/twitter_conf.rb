module TwitterConf
  TEMPLATE = <<EOF
  input {
    twitter {
        consumer_key => "<%= env['TWITTER_CONSUMER_KEY'] %>"
        consumer_secret => "<%= env['TWITTER_CONSUMER_SECRET'] %>"
        oauth_token => "<%= env['TWITTER_OAUTH_TOKEN'] %>"
        oauth_token_secret => "<%= env['TWITTER_OAUTH_SECRET'] %>"
        keywords => <%= keywords %>
        full_tweet => true
    }
  }

  filter {
    ruby {
      path => "#{Rails.root}/lib/extract_user_ids.rb"
    }
  }

  output {
    stdout { }
    elasticsearch {
        hosts         => <%= env['ELASTICSEARCH_HOST'] %>
        index         => "<%= env['ELASTICSEARCH_INDEX'] %>"
        document_type => "tweets"
        template      => "#{Rails.root}/logstash/config/twitter_template.json"
        template_name => "odie"
        template_overwrite => true
    }
  }
EOF

  # It will be easy for the needs of this file to drift out of sync with the
  # context provided by consumers -- let's make it easy to validate.
  # Unfortunately there's not a straightforward way to tell which variables
  # are consumed by an ERB template, so we will have to manually keep the
  # required_vars list up to date, but at least it is in the same file as the
  # template.
  REQUIRED_VARS = [:env, :keywords]

  def valid?(context)
    REQUIRED_VARS.map { |var| context.local_variable_defined? var }.all?
  end
  module_function :valid?

  # ERB#result can't be called with a list of arguments -- it needs a binding.
  def generate(context)
    ERB.new(TEMPLATE).result(context)
  end
  module_function :generate
end
