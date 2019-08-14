# See https://medium.com/@rowanoulton/testing-elasticsearch-in-rails-22a3296d989 .
require 'elasticsearch/extensions/test/cluster'

RSpec.configure do |config|
  config.before :all, elasticsearch: true do
    start_cluster
    wipe_elasticsearch_data
  end

  # Stop elasticsearch cluster after test run
  config.after :suite do
    Elasticsearch::Extensions::Test::Cluster.stop(**es_options) if \
      Elasticsearch::Extensions::Test::Cluster.running?(on: es_port)
  end

  # Start an in-memory Elasticsearch cluster for integration tests. Runs on
  # port 9250 so as not to interfere with development/production clusters.
  # This may throw a warning that the cluster is already running, but you can
  # ignore that.
  def start_cluster
    if Elasticsearch::Extensions::Test::Cluster.running?(on: es_port)
      Elasticsearch::Extensions::Test::Cluster.stop(**es_options)
    end
    Elasticsearch::Extensions::Test::Cluster.start(**es_options)
  end

  def wipe_elasticsearch_data
    client = Elasticsearch::Client.new
    DataSet.all.each do |ds|
      client.delete_by_query index: ds.index_name
      client.indices.delete index: ds.index_name
    end
  end

  def es_port
    9250
  end

  def es_options
    {
      network_host: 'localhost',
      port: es_port,
      number_of_nodes: 1,
      timeout: 120
    }
  end
end
