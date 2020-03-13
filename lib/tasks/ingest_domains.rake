require 'rake'

desc 'Ingest variant URLs from JSON'
task :ingest_variant_urls, [:json_file] => [:environment] do |task, args|
  if args.json_file.empty?
    puts 'Specify the filename of JSON data to be ingested'
    exit
  end

  DomainIngestor.new(args.json_file).ingest
end
