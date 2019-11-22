# == Schema Information
#
# Table name: data_sets
#
#  id              :bigint           not null, primary key
#  hashtags        :hstore
#  index_name      :string
#  num_retweets    :integer
#  num_tweets      :integer
#  num_users       :integer
#  top_mentions    :hstore
#  top_urls        :hstore
#  top_words       :hstore
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  data_config_id  :bigint
#  media_source_id :bigint
#
# Indexes
#
#  index_data_sets_on_data_config_id   (data_config_id)
#  index_data_sets_on_media_source_id  (media_source_id)
#
# Foreign Keys
#
#  fk_rails_...  (data_config_id => data_configs.id)
#

require 'rails_helper'

describe DataSetSerializer do
  let(:ds) { create(
    :data_set, num_users: 10, num_tweets: 50, num_retweets: 5
  ) }

  let(:serializer) { DataSetSerializer.new(ds) }
  let(:hash_data) { serializer.serializable_hash[:data] }

  # If it's missing keys, the other tests might fail for spurious reasons -
  # taking a nonexistent key from the attributes hash will return nil, which
  # could also be the value of an unset attributes on the model. By making
  # sure the key DOES exist we ensure that its value is equal to the model
  # value (and in this case if they are both nil it's fine -- at least we know
  # we are representing the truth.)
  it 'has the expected keys' do
    pending
    expected_keys = [
      :num_users, :num_tweets, :num_retweets, :index_name, :hashtags,
      :time_period, :top_words, :top_urls, :top_sources, :top_mentions,
      :top_retweets
    ].to_set

    actual_keys = hash_data[:attributes].keys.to_set
    assert expected_keys.subset? actual_keys
  end

  it 'reports the number of users' do
    expect(hash_data[:attributes][:num_users]).to eq ds.num_users
  end

  it 'reports the number of tweets' do
    expect(hash_data[:attributes][:num_tweets]).to eq ds.num_tweets
  end

  it 'reports the number of retweets' do
    expect(hash_data[:attributes][:num_retweets]).to eq ds.num_retweets
  end

  it 'reports the elasticsearch index name' do
    expect(hash_data[:attributes][:index_name]).to eq ds.index_name
  end

  it 'reports the top hashtags' do
    expect(hash_data[:attributes][:hashtags]).to eq ds.hashtags
  end
end

# not yet implemented: time period; top words; top URLs; top sources;
# top mentions; top RTs

# add to docs
