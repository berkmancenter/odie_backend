require 'rails_helper'

describe 'CohortDataCollection' do
  it 'writes a logstash config when a cohort is created' do
    create(:cohort)
    create(:big_cohort)
    config = File.read(StreamingDataCollector.filename)
    puts config
    expect(config).to include '"14706139" => "bkc_"'
    expect(config).to include '"15725659" => "early_trump_"'
  end
end
