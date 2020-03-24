# frozen_string_literal: true

# == Schema Information
#
# Table name: data_sets
#
#  id           :bigint           not null, primary key
#  hashtags     :hstore
#  index_name   :string
#  num_retweets :integer
#  num_tweets   :integer
#  num_users    :integer
#  top_mentions :hstore
#  top_sources  :hstore
#  top_urls     :hstore
#  top_words    :hstore
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  cohort_id    :bigint
#
# Indexes
#
#  index_data_sets_on_cohort_id  (cohort_id)
#
# Foreign Keys
#
#  fk_rails_...  (cohort_id => cohorts.id)
#

require 'rails_helper'

describe DataSet do
  let(:ds) { create(:data_set) }

  before(:each) do
    # Keep the data to a readable level so we can check the test suite
    # assertions.
    allow(Rails.application.config).to receive(:tweets_per_user)
                                   .and_return(10)
  end

  context 'index names' do
    it 'sets them on creation' do
      expect(ds.index_name).to be
    end

    it 'protects them against change' do
      orig_name = ds.index_name
      ds.index_name = 'brand-new-index-name'
      ds.save
      expect(ds.reload.index_name).to eq orig_name
    end

    context 'acceptable to elasticsearch' do
      it 'is lowercase' do
        expect(ds.index_name).to eq ds.index_name.downcase
      end

      it 'contains no forbidden characters' do
        expect(ds.index_name.split('') & '#\/*?"<>| ,:'.split('')).to eq []
      end

      it 'does not start with -, _, +, .' do
        expect(['-', '_', '+', '.'].include? ds.index_name.first).to be false
      end
    end
  end

  context 'during data ingestion', elasticsearch: true do
    it 'asks twitter for data on a user' do
      VCR.use_cassette('data set spec') do
        expect_any_instance_of(Twitter::REST::Client)
          .to receive(:user_timeline)
          .once
          .with(1, count: Rails.application.config.tweets_per_user,
                tweet_mode: 'extended')
        allow(ds).to receive(:index_exists?).and_return(true)
        ds.fetch_tweets(1)
      end
    end

    it 'creates an elasticsearch document for each tweet' do
      tweets = [
        { foo: 1 }, { bar: 2 }
      ]
      # Why not expect_any_instance_of(Elasticsearch::Client)? Because the
      # create action is provided by a mixin, so although it's present on all
      # instances, the the test suite can't find it on the class, and therefore
      # can't mock it.
      expect_any_instance_of(Elasticsearch::API::Actions)
        .to receive(:create)
        .once.with(index: ds.index_name, type: '_doc', body: tweets[0].to_json)
      expect_any_instance_of(Elasticsearch::API::Actions)
        .to receive(:create)
        .once.with(index: ds.index_name, type: '_doc', body: tweets[1].to_json)
      ds.store_data(tweets)
    end

    it 'fetches data on all cohort users' do
      VCR.use_cassette('data ingestion') do
        ds.cohort.twitter_ids.each do |id|
          expect(ds).to receive(:fetch_tweets).with(id)
        end
        expect(ds).to receive(:store_data)
                  .exactly(ds.cohort.twitter_ids.length)
                  .times
        ds.ingest_data
      end
    end
  end

  context 'data aggregation', elasticsearch: true do
    it 'sets aggregates appropriately' do
      VCR.use_cassette('data aggregation') do
        cohort = create(:cohort)
        ds_pipelined = DataSet.create(cohort: cohort)
        ds_pipelined.run_pipeline

        expect(ds_pipelined.num_retweets).to eq 5
        expect(ds_pipelined.num_tweets).to eq 10
        expect(ds_pipelined.num_users).to eq 1
        expect(ds_pipelined.top_mentions).to eq({})
        expect(ds_pipelined.top_retweets).to eq({})
        expect(ds_pipelined.top_sources).to eq({})
        expect(ds_pipelined.top_words).to eq({})
        expect(ds_pipelined.top_urls).to eq({})
      end
    end

    it 'does not report below the threshold' do
      stub_const('Extractor::THRESHOLD', 5)
      stub_const('Extractor::TOP_N', 100)    # big enough it cannot interfere

      VCR.use_cassette('data aggregation') do
        cohort = create(:cohort)
        ds_pipelined = DataSet.create(cohort: cohort)
        ds_pipelined.run_pipeline

        expect(ds_pipelined.top_mentions).to eq ({})
        expect(ds_pipelined.top_retweets).to eq({})
        expect(ds_pipelined.top_sources).to eq({})
        expect(ds_pipelined.top_words).to eq({})
        expect(ds_pipelined.top_urls).to eq({})
      end
    end

    it 'only reports the top N places' do
      stub_const('Extractor::THRESHOLD', 1)  # small enough it cannot interfere
      stub_const('Extractor::TOP_N', 1)

      VCR.use_cassette('data aggregation') do
        cohort = create(:cohort)
        ds_pipelined = DataSet.create(cohort: cohort)
        ds_pipelined.run_pipeline

        expect(ds_pipelined.top_mentions).to eq({"BKCHarvard"=>"1", "EngageLab"=>"1",
          "ISOC_NA"=>"1", "JessicaFjeld"=>"1", "coindesk"=>"1", "datasociety"=>"1",
          "draganakaurin"=>"1", "evelyndouek"=>"1", "hackylawyER"=>"1",
          "knightcolumbia"=>"1", "ne8en"=>"1", "omertene"=>"1", "rtushnet"=>"1",
          "techpolicy4POC"=>"1"
        })
        expect(ds_pipelined.top_retweets).to eq({
          "Amazon’s Judging of IP Claims Questioned in Seller Lawsuits (featuring comments from me) https://t.co/QuLXmtIWz3" => {:count=>1, :link=>"https://twitter.com/rtushnet/status/1227619561412997124"},
          "Check out this informative Q&amp;A by our friends at @BKCHarvard, combining aspects of two of our core initiatives, health advocacy and trust in the news, https://t.co/0ClD7Fx1mp" => {:count=>1, :link=>"https://twitter.com/EngageLab/status/1227585647856123904"},
          "Excited to have this out in the world!! I've been slammed on all sides on this one which, despite the saying, I don't think means I am definitely doing anything right😛, but I do think means it's a conversation we need to be having. 1/ https://t.co/h9E0BOujCn" => {:count=>1, :link=>"https://twitter.com/evelyndouek/status/1227282185364918274"},
          "There are sooooo many attempts at codifying ethical principles for AI. This is a fantastic paper from @BKCHarvard @JessicaFjeld @ne8en et al organizing and mapping consensus. With great infographics. https://t.co/xEHD85Lj9C https://t.co/Ng4Cd2OdTV" => {:count=>1, :link=>"https://twitter.com/omertene/status/1227807251227910147"},
          "\"In a rush to apply technical solutions to urban problems regarding public health, we must consider who it’s working for, &amp; how to create more egalitarian spaces &amp; services.” — @draganakaurin for @BKCHarvard https://t.co/D39dG1HJMR" => {:count=>1, :link=>"https://twitter.com/datasociety/status/1228009942420000768"},
        })
        expect(ds_pipelined.top_sources).to eq({"bit.ly"=>"1",
          "cyber.harvard.edu"=>"1", "dash.harvard.edu"=>"1",
          "knightcolumbia.org"=>"1", "medium.com"=>"1",
          "news.bloomberglaw.com"=>"1", "twitter.com"=>"1",
          "workflow.servicenow.com"=>"1"
        })
        expect(ds_pipelined.top_words['resistance']).to eq('1')
        expect(ds_pipelined.top_words['wolfgang']).to eq('1')
        expect(ds_pipelined.top_urls).to eq({
          "bit.ly/2OPEPRC"=>"1", "bit.ly/2ORfrdY"=>"1",
          "cyber.harvard.edu/getinvolved/internships2020"=>"1",
          "dash.harvard.edu/bitstream/handle/1/42160420/HLS%20White%20Paper%20Final_v3.pdf"=>"1",
          "knightcolumbia.org/content/the-rise-of-content-cartels"=>"1",
          "medium.com/berkman-klein-center/navigating-the-digital-city-during-an-outbreak-3b21d2cb5bde"=>"1",
          "medium.com/berkman-klein-center/q-a-misinformation-and-coronavirus-14ce5f3e7d94"=>"1",
          "news.bloomberglaw.com/ip-law/amazons-judging-of-ip-disputes-questioned-in-sellers-lawsuits"=>"1",
          "twitter.com/JessicaFjeld/status/1227945985487314945"=>"1",
          "twitter.com/KGlennBass/status/1227278824200691712"=>"1",
          "workflow.servicenow.com/security-risk/emerging-model-ethical-ai-qa/"=>"1"
        })
      end
    end

    context 'of multiple instances' do
      it 'does not report below the threshold' do
        stub_const('Extractor::THRESHOLD', 5)
        stub_const('Extractor::TOP_N', 100)    # big enough it cannot interfere

        VCR.use_cassette('data aggregation') do
          cohort = create(:cohort)
          ds = DataSet.create(cohort: cohort)
          ds.run_pipeline
          ds.dup.save

          aggs = DataSet.aggregate(DataSet.last(2).pluck(:id))

          expect(aggs[:top_mentions]).to eq({})
          expect(aggs[:top_retweets]).to eq({})
          expect(aggs[:top_sources]).to eq({})
          expect(aggs[:top_words]).to eq({})
          expect(aggs[:top_urls]).to eq({})
        end
      end

      it 'only reports the top N places' do
        stub_const('Extractor::THRESHOLD', 1)  # small enough it cannot interfere
        stub_const('Extractor::TOP_N', 1)

        VCR.use_cassette('data aggregation') do
          cohort = create(:cohort)
          ds = DataSet.create(cohort: cohort)
          ds.run_pipeline
          ds.dup.save

          aggs = DataSet.aggregate(DataSet.last(2).pluck(:id))

          expect(aggs[:top_mentions]).to eq ({"BKCHarvard"=>2, "EngageLab"=>2,
            "ISOC_NA"=>2, "JessicaFjeld"=>2, "coindesk"=>2, "datasociety"=>2,
            "draganakaurin"=>2, "evelyndouek"=>2, "hackylawyER"=>2,
            "knightcolumbia"=>2, "ne8en"=>2, "omertene"=>2, "rtushnet"=>2,
            "techpolicy4POC"=>2
          })
          expect(aggs[:top_retweets]).to eq({
            "\"In a rush to apply technical solutions to urban problems regarding public health, we must consider who it’s working for, &amp; how to create more egalitarian spaces &amp; services.” — @draganakaurin for @BKCHarvard https://t.co/D39dG1HJMR"=>{:count=>1, :link=>"https://twitter.com/datasociety/status/1228009942420000768"},
            "There are sooooo many attempts at codifying ethical principles for AI. This is a fantastic paper from @BKCHarvard @JessicaFjeld @ne8en et al organizing and mapping consensus. With great infographics. https://t.co/xEHD85Lj9C https://t.co/Ng4Cd2OdTV"=>{:count=>1, :link=>"https://twitter.com/omertene/status/1227807251227910147"},
            "Amazon’s Judging of IP Claims Questioned in Seller Lawsuits (featuring comments from me) https://t.co/QuLXmtIWz3"=>{:count=>1, :link=>"https://twitter.com/rtushnet/status/1227619561412997124"},
            "Excited to have this out in the world!! I've been slammed on all sides on this one which, despite the saying, I don't think means I am definitely doing anything right😛, but I do think means it's a conversation we need to be having. 1/ https://t.co/h9E0BOujCn"=>{:count=>1, :link=>"https://twitter.com/evelyndouek/status/1227282185364918274"},
            "Check out this informative Q&amp;A by our friends at @BKCHarvard, combining aspects of two of our core initiatives, health advocacy and trust in the news, https://t.co/0ClD7Fx1mp"=>{:count=>1, :link=>"https://twitter.com/EngageLab/status/1227585647856123904"}
          })
          expect(aggs[:top_sources]).to eq({"bit.ly"=>2, "cyber.harvard.edu"=>2,
            "dash.harvard.edu"=>2, "knightcolumbia.org"=>2, "medium.com"=>2,
            "news.bloomberglaw.com"=>2, "twitter.com"=>2,
            "workflow.servicenow.com"=>2
          })
          expect(aggs[:top_words]['contribute']).to eq(2)
          expect(aggs[:top_words]['graduate']).to eq(2)
          expect(aggs[:top_urls]).to eq({
            "bit.ly/2OPEPRC"=>2, "bit.ly/2ORfrdY"=>2,
            "cyber.harvard.edu/getinvolved/internships2020"=>2,
            "dash.harvard.edu/bitstream/handle/1/42160420/HLS%20White%20Paper%20Final_v3.pdf"=>2,
            "knightcolumbia.org/content/the-rise-of-content-cartels"=>2,
            "medium.com/berkman-klein-center/navigating-the-digital-city-during-an-outbreak-3b21d2cb5bde"=>2,
            "medium.com/berkman-klein-center/q-a-misinformation-and-coronavirus-14ce5f3e7d94"=>2,
            "news.bloomberglaw.com/ip-law/amazons-judging-of-ip-disputes-questioned-in-sellers-lawsuits"=>2,
            "twitter.com/JessicaFjeld/status/1227945985487314945"=>2,
            "twitter.com/KGlennBass/status/1227278824200691712"=>2,
            "workflow.servicenow.com/security-risk/emerging-model-ethical-ai-qa/"=>2
          })
        end
      end
    end
  end
end
