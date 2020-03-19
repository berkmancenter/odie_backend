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

describe CohortSerializer do
  before :all do
    @cohort1, @cohort2 = create_list(:cohort, 2)

    @ds1 = create(:data_set,
                  top_mentions: { 'squid'=>'3' },
                  top_retweets: { 'first tweet test' => { count: '2', link: 'https://firsttweettext.com' } },
                  top_sources:  { 'twitter.com'=>'9', 'http://hasthelargehadroncolliderdestroyedtheworldyet.com/'=>'5'},
                  top_urls:     { 'www.cnn.com/a_story'=>'10' },
                  cohort: @cohort1
                 )
    # These two need to be different, so that the tests can distinguish them
    # and verify that the correct data set is displayed for @cohort2.
    @ds2 = create(:data_set, top_mentions: { 'cuttlefish'=>'3' }, cohort: @cohort2)
    @ds3 = create(:data_set, cohort: @cohort2)
  end

  after :all do
    @ds1.destroy
    @ds2.destroy
    @ds3.destroy
    @cohort1.destroy
    @cohort2.destroy
  end

  it 'includes the description attribute' do
    expect(CohortSerializer.new(@cohort1)
            .serializable_hash[:data][:attributes][:description]).to eq(
      @cohort1.description
    )
  end

  it 'displays the expected data set for a single object' do
    expect(CohortSerializer.new(@cohort1)
            .serializable_hash[:data][:attributes][:latest_data]).to eq(
      DataSetSerializer.new(@ds1).serializable_hash
    )
  end

  it 'displays the most recent data set when there are several' do
    expect(CohortSerializer.new(@cohort2)
            .serializable_hash[:data][:attributes][:latest_data]).to eq(
      DataSetSerializer.new(@ds3).serializable_hash
    )
  end

  it 'aggregates data for collections' do
    hsh = CohortSerializer.new(
      [@cohort1, @cohort2], is_collection: true
    ).serializable_hash

    expect(hsh.keys).to include(:aggregates)
    # to_set makes it order-independent
    expect(hsh[:aggregates][:top_mentions]).to eq(
      { 'squid'=>3, 'plato'=>5, 'aristotle'=>7 }
    )
    expect(hsh[:aggregates][:top_retweets]).to eq(
      { 'first tweet test' => { count: 4, link: 'https://firsttweettext.com' }, 'second tweet text' => { count: 3, link: 'https://secondtweettext.com' }}
    )
    expect(hsh[:aggregates][:top_sources]).to eq (
      { 'godeysladysbook.com'=>7, 'twitter.com'=>13,
        'http://hasthelargehadroncolliderdestroyedtheworldyet.com/'=>5 }
    )
    expect(hsh[:aggregates][:top_words]).to eq(
      { 'stopword'=>10, 'moose'=>148 }
    )
    expect(hsh[:aggregates][:top_urls]).to eq(
      { 'www.cnn.com/a_story'=>14, 'http://bitly.com/98K8eH'=>8 }
    )
    expect(hsh[:aggregates][:hashtags]).to eq(
      { 'llamas'=>14, 'octopodes'=>48 }
    )
  end
end
