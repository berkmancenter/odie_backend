# This class knows how to make index names that are 1) acceptable to
# Elasticsearch, and 2) namespaced via a prefix given on initialization.
class IndexName
  def initialize(prefix)
    @prefix = prefix
  end

  def generate
    "#{@prefix}_#{sanitize(SecureRandom.uuid)}"
  end

  # Remove any elements not permitted in elasticsearch index names:
  # https://www.elastic.co/guide/en/elasticsearch/reference/6.6/indices-create-index.html
  def sanitize(str)
    str.gsub(%r{[\\/*?"<>|\s,#]:}, '').downcase
  end
end
