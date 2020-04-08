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

  before :all do
    # We must reference this before using stub_const on it so that it is loaded;
    # otherwise stub_const will have to guess what it is, and will guess
    # Module, and then things that try to subclass it will fail.
    # https://github.com/rspec/rspec-mocks/issues/1079
    Extractor
  end

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
      stub_const('Extractor::THRESHOLD', 1)  # make sure everything has data
      stub_const('Extractor::TOP_N', 100)    # big enough it cannot interfere

      VCR.use_cassette('data aggregation with many users') do
        cohort = create(:cohort)
        ds_pipelined = DataSet.create(cohort: cohort)
        ds_pipelined.run_pipeline

        expect(ds_pipelined.num_retweets).to eq 5
        expect(ds_pipelined.num_tweets).to eq 10
        expect(ds_pipelined.num_users).to eq 1
        expect(ds_pipelined.top_mentions).to eq({
          "BKCHarvard"=>"3","JessicaFjeld"=>"2", "evelyndouek"=>"1",
          "coindesk"=>"1", "datasociety"=>"1", "draganakaurin"=>"1",
          "EngageLab"=>"1", "hackylawyER"=>"1", "ISOC_NA"=>"1",
          "knightcolumbia"=>"1", "ne8en"=>"1", "omertene"=>"1",
          "rtushnet"=>"1", "techpolicy4POC"=>"1"
        })

        expect(ds_pipelined.top_retweets).to eq({
          "\"In a rush to apply technical solutions to urban problems regarding public health, we must consider who it’s working for, &amp; how to create more egalitarian spaces &amp; services.” — @draganakaurin for @BKCHarvard https://t.co/D39dG1HJMR"=>{:count=>1, :link=>"https://twitter.com/datasociety/status/1228009942420000768"},
          "There are sooooo many attempts at codifying ethical principles for AI. This is a fantastic paper from @BKCHarvard @JessicaFjeld @ne8en et al organizing and mapping consensus. With great infographics. https://t.co/xEHD85Lj9C https://t.co/Ng4Cd2OdTV"=>{:count=>1, :link=>"https://twitter.com/omertene/status/1227807251227910147"},
          "Amazon’s Judging of IP Claims Questioned in Seller Lawsuits (featuring comments from me) https://t.co/QuLXmtIWz3"=>{:count=>1, :link=>"https://twitter.com/rtushnet/status/1227619561412997124"},
          "Excited to have this out in the world!! I've been slammed on all sides on this one which, despite the saying, I don't think means I am definitely doing anything right😛, but I do think means it's a conversation we need to be having. 1/ https://t.co/h9E0BOujCn"=>{:count=>1, :link=>"https://twitter.com/evelyndouek/status/1227282185364918274"},
          "Check out this informative Q&amp;A by our friends at @BKCHarvard, combining aspects of two of our core initiatives, health advocacy and trust in the news, https://t.co\/0ClD7Fx1mp"=>{:count=>1, :link=>"https://twitter.com/EngageLab/status/1227585647856123904"}
        })

        expect(ds_pipelined.top_sources).to eq({
          "bit.ly"=>"2", "medium.com"=>"2", "twitter.com"=>"2",
          "workflow.servicenow.com"=>"1", "dash.harvard.edu"=>"1",
          "news.bloomberglaw.com"=>"1", "knightcolumbia.org"=>"1",
          "cyber.harvard.edu"=>"1"
        })

        expect(ds_pipelined.top_words).to eq({
          "(featuring"=>"1", "-"=>"2", "@bkcharvard"=>"1", "@bkcharvard,"=>"1",
          "@coindesk"=>"1", "@datasociety:"=>"1", "@engagelab:"=>"1",
          "@evelyndouek:"=>"1", "@hackylawyer"=>"1", "@isoc_na"=>"1",
          "@jessicafjeld"=>"1", "@jessicafje…"=>"1", "@omertene:"=>"1",
          "@rtushnet:"=>"1", "@techpolicy4poc"=>"1", "\"in"=>"1",
          "\"smart"=>"1", "advoc…"=>"1", "ai."=>"1", "all-time"=>"1",
          "amazon’s"=>"1", "apply"=>"1", "approach"=>"1", "arrangements."=>"1",
          "aspects"=>"1", "attempts"=>"1", "best"=>"1", "bkc"=>"2",
          "check"=>"2", "cities"=>"1", "claims"=>"1", "codifying"=>"1",
          "collection"=>"1", "combining"=>"1", "comments"=>"1", "consider"=>"1",
          "contribute"=>"1", "core"=>"1", "creative"=>"1", "despite"=>"1",
          "digital"=>"1", "drechsler"=>"1", "ethical"=>"1", "ever,"=>"1",
          "excited"=>"1", "facebook,"=>"1", "fantastic"=>"1", "fed"=>"1",
          "focus"=>"1", "for,…"=>"1", "friends"=>"1", "futile\""=>"1",
          "graduate"=>"1", "health"=>"1", "health,"=>"1", "helm"=>"1",
          "high"=>"1", "high...nevertheless,"=>"1", "housing"=>"1",
          "incentives"=>"1", "informative"=>"1", "initiatives,"=>"1",
          "interns"=>"2", "internships"=>"1", "ip"=>"1", "it’s"=>"1",
          "judging"=>"1", "kostakis"=>"1", "lawsuits"=>"1", "levels"=>"1",
          "libra,"=>"1", "looking"=>"1", "make"=>"1", "many"=>"1", "me)"=>"1",
          "medium"=>"1", "meet"=>"1", "mistrust"=>"1", "money.\""=>"1",
          "must"=>"2", "new"=>"2", "one"=>"1", "out!"=>"1", "paid,"=>"1",
          "paper"=>"1", "people?"=>"1", "perceived"=>"1", "principles"=>"1",
          "privacy-respecting"=>"1", "problems"=>"1", "projects!"=>"1",
          "protagonists"=>"1", "public"=>"1", "q&amp;a"=>"2", "questioned"=>"1",
          "range"=>"1", "regarding"=>"1", "research,"=>"1", "resistance"=>"1",
          "rush"=>"1", "saying,"=>"1", "seller"=>"1", "sides"=>"1",
          "slammed"=>"1", "solutions"=>"1", "sooooo"=>"1", "still"=>"1",
          "strong,"=>"1", "summer"=>"1", "technical"=>"1", "thin…"=>"1",
          "transportation"=>"1", "two"=>"1", "undergrad"=>"1", "urban"=>"1",
          "vasilis"=>"1", "via"=>"1", "which,"=>"1", "wide"=>"1", "wise"=>"1",
          "wolfgang"=>"1", "work"=>"1", "working"=>"1", "world!!"=>"1",
          "“given"=>"1", "⬇️"=>"1", "👇"=>"1", "😎"=>"1",
        })

        expect(ds_pipelined.top_urls).to eq({
          "bit.ly/2OPEPRC"=>"1",
          "bit.ly/2ORfrdY"=>"1",
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

    it 'does not report below the threshold' do
      stub_const('Extractor::THRESHOLD', 2)
      stub_const('Extractor::TOP_N', 100)    # big enough it cannot interfere

      VCR.use_cassette('data aggregation with many users') do
        cohort = create(:cohort)
        ds_pipelined = DataSet.create(cohort: cohort)
        ds_pipelined.run_pipeline

        expect(ds_pipelined.top_mentions).to eq({
          "BKCHarvard"=>"3","JessicaFjeld"=>"2"
        })

        expect(ds_pipelined.top_retweets).to eq({
        })

        expect(ds_pipelined.top_sources).to eq({
          "bit.ly"=>"2", "medium.com"=>"2", "twitter.com"=>"2"
        })

        expect(ds_pipelined.top_words).to eq({
          "-"=>"2", "bkc"=>"2", "check"=>"2", "interns"=>"2", "must"=>"2",
          "new"=>"2", "q&amp;a"=>"2",
        })

        expect(ds_pipelined.top_urls).to eq({
        })
      end
    end

    it 'only reports the top N places' do
      stub_const('Extractor::THRESHOLD', 1)  # small enough it cannot interfere
      stub_const('Extractor::TOP_N', 1)

      VCR.use_cassette('data aggregation with many users') do
        cohort = create(:cohort)
        ds_pipelined = DataSet.create(cohort: cohort)
        ds_pipelined.run_pipeline

        expect(ds_pipelined.top_mentions).to eq({
          "BKCHarvard"=>"3"
        })

        expect(ds_pipelined.top_retweets).to eq({
          "\"In a rush to apply technical solutions to urban problems regarding public health, we must consider who it’s working for, &amp; how to create more egalitarian spaces &amp; services.” — @draganakaurin for @BKCHarvard https://t.co/D39dG1HJMR"=>{:count=>1, :link=>"https://twitter.com/datasociety/status/1228009942420000768"},
          "There are sooooo many attempts at codifying ethical principles for AI. This is a fantastic paper from @BKCHarvard @JessicaFjeld @ne8en et al organizing and mapping consensus. With great infographics. https://t.co/xEHD85Lj9C https://t.co/Ng4Cd2OdTV"=>{:count=>1, :link=>"https://twitter.com/omertene/status/1227807251227910147"},
          "Amazon’s Judging of IP Claims Questioned in Seller Lawsuits (featuring comments from me) https://t.co/QuLXmtIWz3"=>{:count=>1, :link=>"https://twitter.com/rtushnet/status/1227619561412997124"},
          "Excited to have this out in the world!! I've been slammed on all sides on this one which, despite the saying, I don't think means I am definitely doing anything right😛, but I do think means it's a conversation we need to be having. 1/ https://t.co/h9E0BOujCn"=>{:count=>1, :link=>"https://twitter.com/evelyndouek/status/1227282185364918274"},
          "Check out this informative Q&amp;A by our friends at @BKCHarvard, combining aspects of two of our core initiatives, health advocacy and trust in the news, https://t.co\/0ClD7Fx1mp"=>{:count=>1, :link=>"https://twitter.com/EngageLab/status/1227585647856123904"}
        })

        expect(ds_pipelined.top_sources).to eq({
          "bit.ly"=>"2", "medium.com"=>"2", "twitter.com"=>"2"
        })

        expect(ds_pipelined.top_words).to eq({
          "-"=>"2", "bkc"=>"2", "check"=>"2", "interns"=>"2", "must"=>"2",
          "new"=>"2", "q&amp;a"=>"2",
        })

        expect(ds_pipelined.top_urls).to eq({
          "bit.ly/2OPEPRC"=>"1",
          "bit.ly/2ORfrdY"=>"1",
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
        stub_const('Extractor::THRESHOLD', 4)
        stub_const('Extractor::TOP_N', 100)    # big enough it cannot interfere

        # The outer cassette duplicates the inner cassette, but munges all
        # the user IDs so that when we count things by the number of users,
        # all the counts will double. This lets us test aggregation across
        # distinct data sets. The URL being fetched by the outer cassette
        # matches the twitter user ID used by the cohort in the second dataset.
        VCR.use_cassette('data aggregation with many users second dataset') do
          VCR.use_cassette('data aggregation with many users') do
            cohort1 = create(:cohort)
            cohort2 = create(:cohort, twitter_ids: [214706139])
            ds = DataSet.create(cohort: cohort1)
            ds2 = DataSet.create(cohort: cohort2)
            ds.run_pipeline
            ds2.run_pipeline

            aggs = DataSet.aggregate(DataSet.last(2).pluck(:id))

            expect(aggs[:top_mentions]).to eq({
              "BKCHarvard"=>6,"JessicaFjeld"=>4
            })

            expect(aggs[:top_retweets]).to eq({})

            expect(aggs[:top_sources]).to eq({
              "bit.ly"=>4, "medium.com"=>4, "twitter.com"=>4
            })

            expect(aggs[:top_words]).to eq({
              "-"=>4, "bkc"=>4, "check"=>4, "interns"=>4, "must"=>4,
              "new"=>4, "q&amp;a"=>4
            })

            expect(aggs[:top_urls]).to eq({})
          end
        end
      end

      it 'only reports the top N places' do
        stub_const('Extractor::THRESHOLD', 1)  # small enough it cannot interfere
        stub_const('Extractor::TOP_N', 1)

        VCR.use_cassette('data aggregation with many users second dataset') do
          VCR.use_cassette('data aggregation with many users') do
            cohort1 = create(:cohort)
            cohort2 = create(:cohort, twitter_ids: [214706139])
            ds = DataSet.create(cohort: cohort1)
            ds2 = DataSet.create(cohort: cohort2)
            ds.run_pipeline
            ds2.run_pipeline

            aggs = DataSet.aggregate(DataSet.last(2).pluck(:id))

            expect(aggs[:top_mentions]).to eq ({"BKCHarvard"=>6})

            expect(aggs[:top_retweets]).to eq({
              "\"In a rush to apply technical solutions to urban problems regarding public health, we must consider who it’s working for, &amp; how to create more egalitarian spaces &amp; services.” — @draganakaurin for @BKCHarvard https://t.co/D39dG1HJMR"=>{:count=>2, :link=>"https://twitter.com/datasociety/status/1228009942420000768"},
              "There are sooooo many attempts at codifying ethical principles for AI. This is a fantastic paper from @BKCHarvard @JessicaFjeld @ne8en et al organizing and mapping consensus. With great infographics. https://t.co/xEHD85Lj9C https://t.co/Ng4Cd2OdTV"=>{:count=>2, :link=>"https://twitter.com/omertene/status/1227807251227910147"},
              "Amazon’s Judging of IP Claims Questioned in Seller Lawsuits (featuring comments from me) https://t.co/QuLXmtIWz3"=>{:count=>2, :link=>"https://twitter.com/rtushnet/status/1227619561412997124"},
              "Excited to have this out in the world!! I've been slammed on all sides on this one which, despite the saying, I don't think means I am definitely doing anything right😛, but I do think means it's a conversation we need to be having. 1/ https://t.co/h9E0BOujCn"=>{:count=>2, :link=>"https://twitter.com/evelyndouek/status/1227282185364918274"},
              "Check out this informative Q&amp;A by our friends at @BKCHarvard, combining aspects of two of our core initiatives, health advocacy and trust in the news, https://t.co/0ClD7Fx1mp"=>{:count=>2, :link=>"https://twitter.com/EngageLab/status/1227585647856123904"}
            })

            expect(aggs[:top_sources]).to eq({
              "bit.ly"=>4, "medium.com"=>4, "twitter.com"=>4
            })

            expect(aggs[:top_words]).to eq({
              "-"=>4, "bkc"=>4, "check"=>4, "interns"=>4, "must"=>4,
              "new"=>4, "q&amp;a"=>4
            })

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
end
