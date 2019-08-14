require 'rails_helper'

feature 'Data Ingestion' do
  let(:ds) { create(:data_set) }
  user_ids = [14706139] # @BKCHarvard's Twitter ID

  it 'runs a test', elasticsearch: true do
    allow(ds).to receive(:sample_users).and_return(user_ids)
    # Serialization of actual data fetched from the @BKCHarvard timeline.
    # Webmock/VCR don't work here as they don't reach down into whatever the
    # twitter gem is doing to fetch tweets.
    allow(ds).to receive(:fetch_tweets).and_return(
      JSON.parse(File.read(tweet_filepath))['tweets']
    )

    ds.run_pipeline

    expect(ds.num_tweets).to eq 50
    expect(ds.num_users).to eq 1
    expect(ds.num_retweets).to eq 40
    expect(ds.hashtags).to eq (
      {"Zika"=>"1", "Youtube"=>"1", "whyDeconisationOfIPMatters"=>"1",
       "werobot"=>"1", "TwitterDown"=>"1", "Facebook"=>"1", "Instagram"=>"1",
       "WhatsApp"=>"1", "Twitter"=>"1"}
    )
  end

  def tweet_filepath
    File.join(File.dirname(__FILE__), '../support/tweets.json')
  end
end
