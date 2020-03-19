require 'rails_helper'

describe Extractor do
  before :all do
    VCR.use_cassette('data aggregation') do
      # Make our Twitter API request match the recorded cassette (the URL
      # includes a count parameter)
      @tweets_per_user = Rails.application.config.tweets_per_user
      Rails.application.config.tweets_per_user = 10

      ds = create(:data_set)
      @tweets = ds.fetch_tweets(ds.cohort.twitter_ids.first)
    end
  end

  after :all do
    DataSet.destroy_all
    Cohort.destroy_all
    Rails.application.config.tweets_per_user = @tweets_per_user
  end

  before :each do
    # Make sure we're retrieving all data from the data set.
    stub_const("Extractor::THRESHOLD", 1)
    stub_const("Extractor::TOP_N", 100)
  end

  it 'extracts hashtags' do
    expect(HashtagExtractor.new(@tweets).harvest).to eq({"PrincipledAI"=>2})
  end

  it 'extracts mentions' do
    expect(MentionExtractor.new(@tweets).harvest).to eq(
      {"BKCHarvard"=>5, "coindesk"=>1, "datasociety"=>1, "draganakaurin"=>1,
       "EngageLab"=>1, "evelyndouek"=>2, "hackylawyER"=>1, "ISOC_NA"=>1,
       "JessicaFjeld"=>2, "knightcolumbia"=>1, "ne8en"=>1, "omertene"=>1,
       "rtushnet"=>1, "techpolicy4POC"=>1}
     )
  end

  it 'extracts retweets' do
    expect(RetweetExtractor.new(@tweets).harvest).to eq({
      "\"In a rush to apply technical solutions to urban problems regarding public health, we must consider who it’s working for, &amp; how to create more egalitarian spaces &amp; services.” — @draganakaurin for @BKCHarvard https://t.co/D39dG1HJMR"=>{:count=>1, :link=>"https://twitter.com/datasociety/status/1228009942420000768"},
      "There are sooooo many attempts at codifying ethical principles for AI. This is a fantastic paper from @BKCHarvard @JessicaFjeld @ne8en et al organizing and mapping consensus. With great infographics. https://t.co/xEHD85Lj9C https://t.co/Ng4Cd2OdTV"=>{:count=>1, :link=>"https://twitter.com/omertene/status/1227807251227910147"},
      "Amazon’s Judging of IP Claims Questioned in Seller Lawsuits (featuring comments from me) https://t.co/QuLXmtIWz3"=>{:count=>1, :link=>"https://twitter.com/rtushnet/status/1227619561412997124"},
      "Excited to have this out in the world!! I've been slammed on all sides on this one which, despite the saying, I don't think means I am definitely doing anything right😛, but I do think means it's a conversation we need to be having. 1/ https://t.co/h9E0BOujCn"=>{:count=>1, :link=>"https://twitter.com/evelyndouek/status/1227282185364918274"},
      "Check out this informative Q&amp;A by our friends at @BKCHarvard, combining aspects of two of our core initiatives, health advocacy and trust in the news, https://t.co/0ClD7Fx1mp"=>{:count=>1, :link=>"https://twitter.com/EngageLab/status/1227585647856123904"}
    })
  end

  it 'extracts sources' do
    expect(SourceExtractor.new(@tweets).harvest).to eq({
      "bit.ly"=>2, "cyber.harvard.edu"=>1, "dash.harvard.edu"=>1,
      "knightcolumbia.org"=>1, "medium.com"=>2, "news.bloomberglaw.com"=>2,
      "twitter.com"=>2, "workflow.servicenow.com"=>1
    })
  end

  it 'combines sources' do
    create(:source, canonical_host: 'cyber.harvard.edu',
           variant_hosts: ['dash.harvard.edu'])
    create(:source, canonical_host: 'bit.ly',
           variant_hosts: ['medium.com'])
    create(:source, canonical_host: 'twitter.com',
           variant_hosts: ['knightcolumbia.org', 'news.bloomberglaw.com',
                           'workflow.servicenow.com'])

    expect(SourceExtractor.new(@tweets).harvest).to eq({
      "bit.ly"=>4, "cyber.harvard.edu"=>2, "twitter.com"=>6,
    })
  end

  it 'extracts URLs' do
    expect(UrlExtractor.new(@tweets).harvest).to eq({
      "bit.ly/2OPEPRC"=>1, "bit.ly/2ORfrdY"=>1,
      "cyber.harvard.edu/getinvolved/internships2020"=>1,
      "dash.harvard.edu/bitstream/handle/1/42160420/HLS%20White%20Paper%20Final_v3.pdf"=>1,
      "knightcolumbia.org/content/the-rise-of-content-cartels"=>1,
      "medium.com/berkman-klein-center/navigating-the-digital-city-during-an-outbreak-3b21d2cb5bde"=>1,
      "medium.com/berkman-klein-center/q-a-misinformation-and-coronavirus-14ce5f3e7d94"=>1,
      "news.bloomberglaw.com/ip-law/amazons-judging-of-ip-disputes-questioned-in-sellers-lawsuits"=>2,
      "twitter.com/JessicaFjeld/status/1227945985487314945"=>1,
      "twitter.com/KGlennBass/status/1227278824200691712"=>1,
      "workflow.servicenow.com/security-risk/emerging-model-ethical-ai-qa/"=>1
    })
  end

  it 'extracts words' do
    # this test is too annoying if you fetch all the words
    stub_const("Extractor::THRESHOLD", 2)
    expect(WordExtractor.new(@tweets).harvest).to eq({
      "-"=>2, "bkc"=>2, "check"=>2, "interns"=>2, "looking"=>2, "must"=>2,
      "new"=>2, "q&amp;a"=>2, "👇"=>2
    })
  end
end
