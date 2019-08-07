require 'rails_helper'

describe DataSetSerializer do
  let(:ms) do
    MediaSource.new(
      description: 'The first multi-page newspaper published in the Americas',
      name: 'Publick Occurrences Both Forreign and Domestick',
      url: 'https://www.publick-occurrences.com'
    )
  end
  let(:dc) do
    DataConfig.new(
      media_sources: [ms]
    )
  end
  let(:num_users) { 10 }
  let(:num_tweets) { 15 }
  let(:num_retweets) { 5 }
  let(:ds) { DataSet.create(
    media_source: ms, data_config: dc, num_users: num_users,
    num_tweets: num_tweets
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
