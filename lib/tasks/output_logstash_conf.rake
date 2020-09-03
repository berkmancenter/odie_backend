require 'rake'

namespace :odie do
  desc 'Output a logstash config'
  task :write_logstash_conf => [:environment] do |task|
    StreamingDataCollector.write_conf
  end
end
