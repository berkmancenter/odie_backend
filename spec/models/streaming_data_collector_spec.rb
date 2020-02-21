require 'rails_helper'

# These are smoke tests rather than exact ones; they'll fail if we've done
# something terribly wrong, but they aren't strong enough to guarantee success.
describe StreamingDataCollector do
  let(:cc) { create(:cohort_collector) }

  it 'has a filename specific to its CohortCollector' do
    name = StreamingDataCollector.new(cc).filename
    expect(name).to include cc.index_name
  end

  it 'writes a config file' do
    # These will be cleaned up by spec_helper after the suite; no need to handle
    # that now.
    sdf = StreamingDataCollector.new(cc)
    sdf.write_conf
    expect(File.file? sdf.filename).to be true
  end

  it 'runs logstash (in the background)' do
    pending 'not sure how to test this effectively'
    sdf = StreamingDataCollector.new(cc)
    sdf.write_conf

    # This also stubs out the method so we are not in fact spawning logstash
    # processes and piling up junk data. (And it tests a prior implementation --
    # it doesn't make sense for the current one.)
    expect(sdf).to receive(:system).with("timeout #{Rails.application.config.logstash_run_time} #{Rails.application.config.logstash_command} -f #{sdf.filename} &")
    sdf.kickoff
  end

  it 'URL-encodes keywords' do
    cc.update_column(:keywords, ['ümlauts', 'ácutes', '汉字', '훈민정음'])

    sdf = StreamingDataCollector.new(cc)
    sdf.write_conf

    contents = File.read(sdf.filename)

    expect(contents).to include "%C3%BCmlauts"
    expect(contents).to include "%C3%A1cutes"
    expect(contents).to include "%E6%B1%89%E5%AD%97"
    expect(contents).to include "%ED%9B%88%EB%AF%BC%EC%A0%95%EC%9D%8C"
  end
end
