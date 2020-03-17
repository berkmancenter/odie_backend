# == Schema Information
#
# Table name: cohort_collectors
#
#  id         :bigint           not null, primary key
#  end_time   :datetime
#  index_name :string
#  keywords   :text             default([]), is an Array
#  start_time :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

describe CohortCollector do
  context 'when monitoring twitter' do
    before :each do
      @sdf = instance_double(StreamingDataCollector).as_null_object
      allow(StreamingDataCollector).to receive(:new).and_return(@sdf)

      @cc = create(:cohort_collector)
      allow(@cc).to receive(:services_available?).and_return true
    end

    it 'makes a twitter conf' do
      expect(@sdf).to receive(:write_conf)

      @cc.monitor_twitter
    end

    it 'kicks off a data run' do
      expect(@sdf).to receive(:kickoff)

      @cc.monitor_twitter
    end

    it 'updates its start and end times' do
      expect(@cc.start_time).not_to be_present
      expect(@cc.end_time).not_to be_present

      @cc.monitor_twitter

      expect(@cc.start_time).to be_present
      expect(@cc.end_time).to be_present
      expect(@cc.start_time).to be_within(1.second).of(Time.now)
      expect(@cc.end_time).to be_within(1.second)
        .of(Time.now + CohortCollector.logstash_run_time)
    end
  end

  context 'when creating cohorts' do
    it 'creates a cohort with correct properties' do
      ids = ['1', '2']
      cc = build(:cohort_collector, :with_times, :with_keywords)
      allow(cc).to receive(:sample_users).and_return(ids)

      cc.create_cohort
      expect(Cohort.count).to eq 1

      expect(Cohort.last.twitter_ids).to eq ids
      expect(Cohort.last.description).to include(cc.readable_date(cc.start_time))
      expect(Cohort.last.description).to include(cc.readable_date(cc.end_time))
      expect(Cohort.last.description).to include(cc.keywords.to_s)
    end

    it 'correctly samples user IDs', elasticsearch: true do
      cached_config = Rails.application.config.num_users
      Rails.application.config.num_users = 2

      es = double('Elasticsearch::Client')
      allow(Elasticsearch::Client).to receive(:new).and_return(es)
      allow(es).to receive(:search).and_return sample_id_str_data

      cc = build(:cohort_collector)
      users = cc.sample_users

      expect(users.length).to eq 2
      expect(users.uniq.length).to eq users.length
      expect(
        ['1206966411928784896', '1206966412989882368', '1206966412604006401',
         '1206966412020813826', '1206966414369869824', '1206966414952861696',
         '1206966416647180288', '1206966416647368708', '1206966420678074368',
         '1206966423001665536']
       ).to include(*users)

      Rails.application.config.num_users = cached_config
    end

    it "won't create a cohort while data collection is still running" do
      cc = build(:cohort_collector, end_time: Time.now + 1.hour)
      cc.create_cohort
      expect(Cohort.count).to eq 0
    end
  end

  context 'when extracting logstash run times' do
    it 'handles seconds' do
      allow(Rails.application.config).to receive(:logstash_run_time).and_return '2s'
      expect(CohortCollector.logstash_run_time).to eq 2.seconds
    end

    it 'handles minutes' do
      allow(Rails.application.config).to receive(:logstash_run_time).and_return '2m'
      expect(CohortCollector.logstash_run_time).to eq 2.minutes
    end

    it 'handles hours' do
      allow(Rails.application.config).to receive(:logstash_run_time).and_return '2h'
      expect(CohortCollector.logstash_run_time).to eq 2.hours
    end

    it 'handles days' do
      allow(Rails.application.config).to receive(:logstash_run_time).and_return '2d'
      expect(CohortCollector.logstash_run_time).to eq 2.days
    end

    it 'does not handle other things' do
      allow(Rails.application.config).to receive(:logstash_run_time).and_return '1'
      expect { CohortCollector.logstash_run_time }.to raise_error(RuntimeError)

      allow(Rails.application.config).to receive(:logstash_run_time).and_return 'cows'
      expect { CohortCollector.logstash_run_time }.to raise_error(RuntimeError)
    end
  end

  context 'upon initialization' do
    it 'sets an index name' do
      sq = build(:search_query)
      cc = CohortCollector.create(search_queries: [sq])
      expect(cc.index_name).to be
    end

    it 'sets its keywords' do
      sq = build(:search_query)
      cc = CohortCollector.create(search_queries: [sq])
      expect(cc.keywords).to eq(sq.all_search_terms)
    end

    it 'sets its keywords when there are known variants' do
      sq = build(:search_query)
      create(:source, canonical_host: sq.url)
      cc = CohortCollector.create(search_queries: [sq])
      expect(cc.keywords).to match_array(sq.all_search_terms)
    end

    it 'can set keywords from multiple search queries' do
      sq = build(:search_query, keyword: 'red')
      sq2 = build(:search_query, keyword: 'blue')
      cc = CohortCollector.create(search_queries: [sq, sq2])
      expect(cc.keywords).to match_array(['red', 'blue'])
    end

    it 'persists keywords even when underlying queries change' do
      sq = build(:search_query, keyword: 'cows')
      cc = CohortCollector.create(search_queries: [sq])

      sq.keyword = 'bubbles'
      sq.save

      expect(cc.keywords).to eq(['cows'])
    end
  end

  # This was generated from briefly running a logstash pipeline and then
  # performing a query of the form in CohortCollector.sample_users. That is to
  # say, it's realistic data.
  def sample_id_str_data
    {"took"=>8, "timed_out"=>false, "_shards"=>{"total"=>1, "successful"=>1, "skipped"=>0, "failed"=>0}, "hits"=>{"total"=>1068, "max_score"=>1.0, "hits"=>[{"_index"=>"odie", "_type"=>"_doc", "_id"=>"axeTFG8Bw71UFw7bUjyY", "_score"=>1.0, "_source"=>{"id_str"=>"1206966411928784896"}}, {"_index"=>"odie", "_type"=>"_doc", "_id"=>"bReTFG8Bw71UFw7bUzyV", "_score"=>1.0, "_source"=>{"id_str"=>"1206966412989882368"}}, {"_index"=>"odie", "_type"=>"_doc", "_id"=>"bheTFG8Bw71UFw7bUzy-", "_score"=>1.0, "_source"=>{"id_str"=>"1206966412604006401"}}, {"_index"=>"odie", "_type"=>"_doc", "_id"=>"bBeTFG8Bw71UFw7bUzxa", "_score"=>1.0, "_source"=>{"id_str"=>"1206966412020813826"}}, {"_index"=>"odie", "_type"=>"_doc", "_id"=>"bxeTFG8Bw71UFw7bVTwh", "_score"=>1.0, "_source"=>{"id_str"=>"1206966414369869824"}}, {"_index"=>"odie", "_type"=>"_doc", "_id"=>"cBeTFG8Bw71UFw7bVTxn", "_score"=>1.0, "_source"=>{"id_str"=>"1206966414952861696"}}, {"_index"=>"odie", "_type"=>"_doc", "_id"=>"cReTFG8Bw71UFw7bVzxq", "_score"=>1.0, "_source"=>{"id_str"=>"1206966416647180288"}}, {"_index"=>"odie", "_type"=>"_doc", "_id"=>"cheTFG8Bw71UFw7bWDwo", "_score"=>1.0, "_source"=>{"id_str"=>"1206966416647368708"}}, {"_index"=>"odie", "_type"=>"_doc", "_id"=>"cxeTFG8Bw71UFw7bWzwB", "_score"=>1.0, "_source"=>{"id_str"=>"1206966420678074368"}}, {"_index"=>"odie", "_type"=>"_doc", "_id"=>"dReTFG8Bw71UFw7bXDzn", "_score"=>1.0, "_source"=>{"id_str"=>"1206966423001665536"}}]}}
  end
end
