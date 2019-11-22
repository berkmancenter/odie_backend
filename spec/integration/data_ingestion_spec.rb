require 'rails_helper'

feature 'Data Ingestion' do
  let(:ds) { create(:data_set) }
  user_ids = [14706139] # @BKCHarvard's Twitter ID

  it 'runs a test', elasticsearch: true do
    allow(ds).to receive(:sample_users).and_return(user_ids)
    # Serialization of actual data fetched from the @BKCHarvard timeline.
    # Webmock/VCR don't work here as they don't reach down into whatever the
    # twitter gem is doing to fetch tweets.
    allow(ds).to receive(:fetch_tweets).and_return(tweet_objects)

    ds.run_pipeline

    expect(ds.num_tweets).to eq 50
    expect(ds.num_users).to eq 1
    expect(ds.num_retweets).to eq 28
    expect(ds.hashtags).to eq (
      {"BetweenTruthAndPower"=>"1", "livestreaming"=>"2", "Sharenthood"=>"1",
       "CyberlawClinicAt20"=>"2", "Napster"=>"2", "MacFellow"=>"1",
       "disinformation"=>"2", "disinfocon"=>"1", "FesTech19"=>"1"}
    )
    expect(ds.top_urls).to eq (
      {"https://cyber.harvard.edu/publication/2019/content-and-conduct"=>"3",
      "https://cyber.harvard.edu/events/between-truth-and-power-legal-constructions-informational-capitalism"=>"3",
      "https://cyber.harvard.edu/story/2019-11/opportunity-clinical-instructor"=>"2",
      "https://cyber.harvard.edu/events/sharenthood-how-parents-teachers-and-other-trusted-adults-harm-youth-privacy-opportunity"=>"2",
      "https://cyber.harvard.edu/events/napster20-reflections-internets-most-controversial-music-file-sharing-service"=>"4",
      "https://twitter.com/cyberlawclinic/status/1196441310510469120"=>"2",
      "https://datasociety.net/blog/2019/10/22/call-for-2020-2021-faculty-fellows/"=>"2",
      "http://hvrdlaw.me/Zedh50xb9TD"=>"2",
      "https://www.theatlantic.com/ideas/archive/2019/11/let-juries-review-facebook-ads/601996/"=>"2",
      "https://cyber.harvard.edu/story/2019-11/illuminating-flows-and-redactions-content-online"=>"3",
      "https://cyber.harvard.edu/events/california-consumer-privacy-act-what-it-means-companies-and-lawyers"=>"2",
      "https://twitter.com/BKCHarvard/status/1192460757658554368"=>"2",
      "https://cyber.harvard.edu/events/regulating-social-media"=>"2"}
    )
    expect(ds.top_words).to eq (
      {"ai"=>"6", "⬇️⬇️⬇️"=>"7", "@bkcharvard"=>"6", "facebook"=>"6", "today"=>"5"}
    )
    expect(ds.top_mentions).to eq (
      {"ArcadiaFund"=>"6", "BKCHarvard"=>"20", "JessicaFjeld"=>"6",
      "cyberlawclinic"=>"6", "zittrain"=>"8"}
  end

  # Rehydrate JSON into Twitter::Tweet objects, since that's what DataSets
  # parse at runtime.
  def tweet_objects
    tweet_json = JSON.parse(File.read(tweet_filepath))['tweets']
    tweet_json.map { |tweet| Twitter::Tweet.new(tweet.deep_symbolize_keys) }
  end

  def tweet_filepath
    File.join(File.dirname(__FILE__), '../support/tweets.json')
  end
end
