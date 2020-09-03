RSpec.configure do |config|
  config.before :all, elasticsearch: true do
    wipe_elasticsearch_data
    ENV['PRETEST_ELASTICSEARCH_URL'] = ENV['ELASTICSEARCH_URL']
    ENV['ELASTICSEARCH_URL'] = "http://#{es_host}:#{es_port}"
  end

  # Stop elasticsearch cluster after test run
  config.after :suite do
    ENV['ELASTICSEARCH_URL'] = ENV['PRETEST_ELASTICSEARCH_URL']
    ENV.delete('PRETEST_ELASTICSEARCH_URL')
  end

  def wipe_elasticsearch_data
    client = Elasticsearch::Client.new(host: ENV['ELASTICSEARCH_URL'])
    Cohort.all.each do |c|
      client.indices.delete index: "#{c.index_prefix}*"
    end
  end

  def es_host
    ENV['ELASTICSEARCH_DOCKER_TEST_URL'] || 'localhost'
  end

  def es_port
    ENV['ELASTICSEARCH_DOCKER_TEST_PORT'] || 9250
  end
end
