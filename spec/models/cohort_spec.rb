# frozen_string_literal: true

# == Schema Information
#
# Table name: cohorts
#
#  id          :bigint           not null, primary key
#  description :text
#  twitter_ids :text             default([]), is an Array
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#


require 'rails_helper'

describe Cohort do
  it 'can find the latest data set' do
    cohort = build(:cohort)
    create_list(:data_set, 2, cohort: cohort)
    expect(cohort.latest_data_set.id).to eq DataSet.last.id
  end

  it 'can create a data set based on itself', elasticsearch: true do
    # The cassette here is data from a real Twitter API call, but truncated --
    # the default of 50 tweets is too long to readily comb through to be sure
    # the aggregations are correct. One tweet has also been duplicated in order
    # to ensure that some objects occur more than once.
    VCR.use_cassette('cohort creates a data set based on itself') do
      cohort = build(:cohort)
      cohort.collect_data
      ds = DataSet.last
      expect(ds.cohort.id).to eq cohort.id
      expect(ds.num_users).to eq 1
      expect(ds.num_tweets).to eq 8
      expect(ds.num_retweets).to eq 5
      expect(ds.top_mentions).to eq({
        "evelyndouek"=>"3",
        "BKCHarvard"=>"6",
        "farman"=>"2",
        "ruha9"=>"4",
        })
      expect(ds.top_retweets).to eq({
        "If you haven't yet watched the video of @ruha9 speak at @BKCHarvard on The New Jim Code,take some time today to listen to her speak on the intersection of race and technology,carceral technoscience,&amp; liberatory imagination in everyday life. https://t.co/VUbrXxmYeD"=> {:count=>2, :link=>"https://twitter.com/farman/status/1227305335901302785"}
      })
      # These numbers are lower than you'll see grepping through the VCR
      # cassette because 1) only the expanded_url field is considered and 2)
      # some URLs appear in the User entity (e.g. in their Twitter bio) and
      # thus should not be counted here -- we're only looking at (re)tweets.
      expect(ds.top_sources).to eq ({
        "cyber.harvard.edu"=>"3",
        "news.bloomberglaw.com"=>"2",
        "twitter.com"=>"2"
      })
      expect(ds.top_urls).to eq ({
        "news.bloomberglaw.com/ip-law/amazons-judging-of-ip-disputes-questioned-in-sellers-lawsuits"=>"2",
        "cyber.harvard.edu/events/new-jim-code"=>"2"
      })
      expect(ds.top_words).to eq({
        "jim"=>"2", "new"=>"3", "yet"=>"2", "time"=>"2", "speak"=>"2",
        "today"=>"2", "video"=>"2", "@ruha9"=>"2", "her…"=>"2", "listen"=>"2",
        "looking"=>"2", "watched"=>"2", "code,take"=>"2", "platforms"=>"2",
        "@farman:if"=>"2", "@bkcharvard"=>"2"
      })
      expect(ds.hashtags).to eq({})
    end
  end

  context :aggregation do
    before :all do
      @cohorts = create_list(:cohort, 2)
      create(:data_set,
        cohort: @cohorts.first,
        top_mentions: { 'plato'=>'5', 'aristotle'=>'7' },
        top_sources: { 'godeysladysbook.com'=>'7', 'twitter.com'=>'4' },
        top_urls: { 'www.cnn.com/a_story'=>'4', 'http://bitly.com/98K8eH'=>'8'},
        top_words: { 'stopword'=>'5', 'moose'=>'74' },
        hashtags: { 'llamas'=>'7', 'octopodes'=>'24' }
      )
      create(:data_set,
        cohort: @cohorts.second,
        top_mentions: { 'plato'=>'10', 'socrates'=>'7' },
        top_sources: { 'twitter.com'=>'4', 'livejournal.com'=>'4' },
        top_urls: { 'www.cnn.com/a_story'=>'1' },
        top_words: { 'stopword'=>'5', 'bats'=>'7' },
        hashtags: { 'alpacas'=>'7', 'octopodes'=>'24' }
      )
    end

    after :all do
      DataSet.destroy_all
      Cohort.destroy_all
      Retweet.destroy_all
    end

    it 'can aggregate data from multiple cohorts' do
      aggs = Cohort.aggregate(@cohorts.pluck(:id))
      expect(aggs[:top_mentions]).to eq({
        'plato'=>15, 'aristotle'=>7, 'socrates'=>7
      })
      expect(aggs[:top_retweets]).to eq({
        'first tweet test' => { count: 4, link: 'https://firsttweettext.com' }, 'second tweet text' => { count: 6, link: 'https://secondtweettext.com' }
      })
      expect(aggs[:top_sources]).to eq({
        'godeysladysbook.com'=>7, 'twitter.com'=>8, 'livejournal.com'=>4
      })
      expect(aggs[:top_urls]).to eq({
        'www.cnn.com/a_story'=>5, 'http://bitly.com/98K8eH'=>8
      })
      expect(aggs[:top_words]).to eq({
        'stopword'=>10, 'moose'=>74, 'bats'=>7
      })
      expect(aggs[:hashtags]).to eq({
        'llamas'=>7, 'octopodes'=>48, 'alpacas'=>7
      })
    end
  end
end
