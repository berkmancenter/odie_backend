require 'json'
require_relative '../app/models/source.rb'

class DomainIngestor
  def initialize(json_file)
    @json_file = json_file
  end

  def ingest
    data = JSON.parse(File.read(@json_file))
    data.each do |k, v|
      next if k == v

      puts "Adding variant #{k} to host #{v}"

      s = Source.find_or_create_by(canonical_host: v)
      variants = (s.variant_hosts || [] ) << k
      s.update_columns(variant_hosts: variants)
    end
  end
end
