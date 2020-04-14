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
    Retweet.destroy_all
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
    expect(Cohort).to receive(:aggregate)
                   .with(contain_exactly(
                     @cohort1.id, @cohort2.id
                   ))
    hsh = CohortSerializer.new(
      [@cohort1, @cohort2], is_collection: true
    ).serializable_hash

    expect(hsh.keys).to include(:aggregates)
  end
end
