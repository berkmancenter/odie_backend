require 'rails_helper'

describe MediaSourceSerializer do
  let(:ds1) { create(:data_set,
                     top_mentions: { 'squid'=>'3' },
                     top_retweets: { 'first tweet text'=>'2' },
                     top_sources:  { 'twitter.com'=>'9', 'http://hasthelargehadroncolliderdestroyedtheworldyet.com/'=>'1'},
                     top_urls:     { 'www.cnn.com/a_story'=>'10' }
                    )
            }
  let(:ds2) { create(:data_set) }

  it 'aggregates data' do
    hsh = MediaSourceSerializer.new(
      [ds1.media_source, ds2.media_source], is_collection: true
    ).aggregated_hash

    expect(hsh.keys).to include(:aggregate_data)
    expect(hsh[:aggregate_data][:num_users]).to eq \
      ds1.num_users + ds2.num_users
    expect(hsh[:aggregate_data][:num_tweets]).to eq \
      ds1.num_tweets + ds2.num_tweets
    expect(hsh[:aggregate_data][:num_retweets]).to eq \
      ds1.num_retweets + ds2.num_retweets
    # to_set makes it order-independent
    expect(hsh[:aggregate_data][:index_name].to_set).to eq \
      [ds1.index_name, ds2.index_name].to_set
    expect(hsh[:aggregate_data][:top_mentions]).to eq \
      ({ 'squid'=>3, 'plato'=>5, 'aristotle'=>7 })
    expect(hsh[:aggregate_data][:top_retweets]).to eq \
      ({ 'first tweet text'=>4, 'second tweet text'=>3})
    expect(hsh[:aggregate_data][:top_sources]).to eq \
      ({ 'godeysladysbook.com'=>7, 'twitter.com'=>13, 'http://hasthelargehadroncolliderdestroyedtheworldyet.com/'=>1 })
    expect(hsh[:aggregate_data][:top_words]).to eq \
      ({ 'stopword'=>10, 'moose'=>148 })
    expect(hsh[:aggregate_data][:hashtags]).to eq \
      ({ 'llamas'=>14, 'octopodes'=>48 })
  end
end
