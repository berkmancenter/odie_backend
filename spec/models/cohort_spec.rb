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
      cohort = create(:cohort)
      cohort.collect_data
      ds = DataSet.last
      expect(ds.cohort.id).to eq cohort.id
      expect(ds.num_users).to eq 1
      expect(ds.num_tweets).to eq 8
      expect(ds.num_retweets).to eq 5
      expect(ds.top_mentions).to eq({"BKCHarvard"=>"2", "farman"=>"2", "ruha9"=>"2"})
      expect(ds.top_retweets).to eq({
        "If you haven't yet watched the video of @ruha9 speak at @BKCHarvard on The New Jim Code,take some time today to listen to her speak on the intersection of race and technology,carceral technoscience,&amp; liberatory imagination in everyday life. https://t.co/VUbrXxmYeD"=> {:count=>2, :link=>"https://twitter.com/farman/status/1227305335901302785"}
      })
      # These numbers are lower than you'll see grepping through the VCR
      # cassette because 1) only the expanded_url field is considered and 2)
      # some URLs appear in the User entity (e.g. in their Twitter bio) and
      # thus should not be counted here -- we're only looking at (re)tweets.
      expect(ds.top_sources).to eq ({
        "cyber.harvard.edu"=>"2"
      })
      expect(ds.top_urls).to eq ({
        "cyber.harvard.edu/events/new-jim-code"=>"2"
      })
      expect(ds.top_words).to eq({
        "jim"=>"2", "new"=>"2", "yet"=>"2", "time"=>"2", "speak"=>"2",
        "today"=>"2", "video"=>"2", "@ruha9"=>"2", "her…"=>"2", "listen"=>"2",
        "watched"=>"2", "code,take"=>"2", "@farman:if"=>"2", "@bkcharvard"=>"2"
      })
      expect(ds.hashtags).to eq({})
    end
  end

  context :aggregation do
    it 'can aggregate data from multiple cohorts' do
      cohorts = create_list(:cohort, 2)
      ds1 = create(:data_set, cohort: Cohort.last)
      ds2 = create(:data_set, cohort: Cohort.second_to_last)

      expect(DataSet).to receive(:aggregate)
                     .with(contain_exactly(ds1.id, ds2.id))
      Cohort.aggregate(cohorts.pluck(:id))
    end

    it 'chooses the latest data set when aggregating data from multiple cohorts' do
      cohorts = create_list(:cohort, 2)
      ds, ds1 = create_list(:data_set, 2, cohort: Cohort.last)
      ds, ds2 = create_list(:data_set, 2, cohort: Cohort.second_to_last)

      expect(DataSet).to receive(:aggregate)
                     .with(contain_exactly(ds1.id, ds2.id))
      Cohort.aggregate(cohorts.pluck(:id))
    end
  end
end
