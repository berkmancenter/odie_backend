module TwitterConf
  TEMPLATE = <<EOF
input {
  twitter {
    consumer_key => "<%= env['TWITTER_CONSUMER_KEY'] %>"
    consumer_secret => "<%= env['TWITTER_CONSUMER_SECRET'] %>"
    oauth_token => "<%= env['TWITTER_OAUTH_TOKEN'] %>"
    oauth_token_secret => "<%= env['TWITTER_OAUTH_SECRET'] %>"
    follows => ["<%= acct_ids_to_cohort_prefix.keys().join('","') %>"]
    full_tweet => true
    ignore_retweets => false
    add_field => { "[@metadata][source]" => "api" }
  }

  file {
    path => "<%= env['TWEETS_DIR'] %>/*.ndjson"
    file_completed_action => "delete"
    mode => "read"
    codec => "json"
	file_chunk_size => 2097152
    add_field => {
      "[@metadata][source]" => "file"
      "[@metadata][filename]" => "[path]"
    }
  }
}

filter {
  date {
    match => ["created_at", "E MMM dd HH:mm:ss Z yyyy"]
  }

  translate {
    field => "[user][id_str]"
    destination => "[@metadata][cohort_prefix]"
    dictionary => {<% acct_ids_to_cohort_prefix.each do |acct_id, cohort_prefix| %>
      <%= '"' + acct_id.to_s + '" => "' + cohort_prefix + '"' %><% end %>
    }
    fallback => "unknown_"
  }
}

output {
  elasticsearch {
    hosts => "<%= env['ELASTICSEARCH_URL'] %>"
    index => "%{[@metadata][cohort_prefix]}%{+yyyy-ww}"
    document_id => "%{[id]}"
  }
}
EOF

  # It will be easy for the needs of this file to drift out of sync with the
  # context provided by consumers -- let's make it easy to validate.
  # Unfortunately there's not a straightforward way to tell which variables
  # are consumed by an ERB template, so we will have to manually keep the
  # required_vars list up to date, but at least it is in the same file as the
  # template.
  REQUIRED_VARS = [:env, :acct_ids_to_cohort_prefix]

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
