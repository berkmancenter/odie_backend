# See https://medium.com/@rowanoulton/testing-elasticsearch-in-rails-22a3296d989 .
require 'elasticsearch/extensions/test/cluster'

RSpec.configure do |config|
  config.before :all, elasticsearch: true do
    start_cluster
    wipe_elasticsearch_data
    # When the elasticsearch clients in the model look for elasticsearch, they
    # should find the test cluster, not the normal cluster.
    if ENV['ELASTICSEARCH_DOCKER_TEST'].nil?
      ENV['CACHED_ELASTICSEARCH_URL'] = ENV['ELASTICSEARCH_URL']
    end
    ENV['ELASTICSEARCH_URL'] = "http://#{es_host}:#{es_port}"
  end

  # Stop elasticsearch cluster after test run
  config.after :suite do
    break unless ENV['ELASTICSEARCH_DOCKER_TEST'].nil?

    Elasticsearch::Extensions::Test::Cluster.stop(es_options)
    ENV['ELASTICSEARCH_URL'] = ENV['CACHED_ELASTICSEARCH_URL']
    ENV.delete('CACHED_ELASTICSEARCH_URL')
  end

  # Start an in-memory Elasticsearch cluster for integration tests. Runs on
  # port 9250 so as not to interfere with development/production clusters.
  # This may throw a warning that the cluster is already running, but you can
  # ignore that.
  def start_cluster
    return unless ENV['ELASTICSEARCH_DOCKER_TEST'].nil?

    if Elasticsearch::Extensions::Test::Cluster.running?(es_options)
      Elasticsearch::Extensions::Test::Cluster.stop(es_options)
    end
    Elasticsearch::Extensions::Test::Cluster.start(es_options)
  end

  def wipe_elasticsearch_data
    client = Elasticsearch::Client.new
    DataSet.all.each do |ds|
      client.delete_by_query index: ds.index_name
      client.indices.delete index: ds.index_name
    end
  end

  def es_host
    ENV['ELASTICSEARCH_DOCKER_TEST_URL'] || 'localhost'
  end

  def es_port
    ENV['ELASTICSEARCH_DOCKER_TEST_PORT'] || 9250
  end

  def es_options
    {
      network_host: es_host,
      port: es_port,
      number_of_nodes: 1,
      path_data: '/tmp/odie_elasticsearch_test',
      path_logs: '/tmp/log/odie_elasticsearch',
    }
  end
end
