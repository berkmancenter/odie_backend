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
    )
    expect(ds.top_sources).to eq (
      {"twitter.com"=>"13", "cyber.harvard.edu"=>"26", "hvrdlaw.me"=>"3",
      "datasociety.net"=>"2", "brk.mn"=>"2", "www.theatlantic.com"=>"2"}
    )
    # unfortunately, our test sample RTed a lot of things 1 time each...
    expect(ds.top_retweets).to eq (
      {"\"Content and Conduct:\nHow English Wikipedia Moderates Harmful Speech\"\n\nI was pleased to have been a part of creating this report.\nCheck it out!\nhttps://t.co/1yZEqELg7z\n\n@BKCHarvard"=>"1", "Sometimes you just eat lunch and sometimes you eat lunch while @julie17usc blows your tiny mind 🤯 with a lecture on her new book #BetweenTruthAndPower : “power interprets regulation as damage and routes around it” https://t.co/vng6oefoRW"=>"1", "I'm excited to announce the release of this report. As part of the study, I interviewed 16 Wikipedia editors about how Wikipedians address harmful content. In this thread, I’ll share some of the key takeaways from the conversations (1/7). https://t.co/YuWTyMJgRj"=>"1", "Heading up to @BKCHarvard today to talk about Between Truth and Power https://t.co/GJHPPqYwlZ"=>"1", "First @BKCHarvard Ciné Club is LIVE! Tonight we are watching Hi Ai, a movie by Isa Willinger. Then we’ll discuss philosophical implications of a possible AI Centered future. Thanks to fellow Léo Cortana for Organizing! https://t.co/Sw1QhJiCXi"=>"1", "Why we should think before we talk about our kids online. @LeahAPlunkett will be #livestreaming from @BKCHarvard today at noon to discuss her book #Sharenthood: How Parents, Teachers, and Other Trusted Adults Harm Youth Privacy &amp; Opportunity  https://t.co/RAhRt42esb"=>"1", "Psyched for this first official #CyberlawClinicAt20 event—very appropriate that it’s on the topic of the #Napster decision’s 20th anniversary! 1999 was a long time ago... https://t.co/FJuoxVkTrx"=>"1", "Live webcast Today at 12pm https://t.co/TOq2QO6KzD https://t.co/wGXHAFr7i3"=>"1", "Read how Benjamin Mako Hill an assistant professor at the UW is using Hyak, the on-site supercomputer, to understand how online communities work. \n\nhttps://t.co/8HKbaogCnc\n\n@BKCHarvard @comdatasci @UWCSSS @IQSS @uwdub https://t.co/HqrosubBXm"=>"1", "Apply to be a 2020-2021 @datasociety Faculty Fellow by December 17: https://t.co/SqWhUslwVn"=>"1", ".@DanielleCitron warns of the societal impacts of online video content, online mobs + coordinated harassment, and chats about what's next for her research as a #MacFellow (with @bafeldman for @intelligencer) https://t.co/ps0lSk3KfK"=>"1", "MONDAY, 11/18 at 12pm! @cbavitz, @nancybaym, David Herlihy of @NU_CAMD, and Jennifer Jenkins of @DukeLaw reflect on the twentieth anniversary of Napster 🎧💻🎶 RSVP and more information ⬇️⬇️⬇️https://t.co/v5eLBmwVnD"=>"1", "\"Even Facebook does not trust Facebook to decide unilaterally which ads are false and misleading,\" @zittrain writes. \"So if the ads are to be weighed at all, someone else has to render judgment.\" https://t.co/0W0QPFbMeV"=>"1", "Thanks for including me in Faculty Voices  @Harvard_Law. I’m thinking about my academic colleagues &amp; students in much, much less privileged places - all the way from HK to Chile, and remain committed to do what I can to support you and learn from you. cc: @BKCHarvard https://t.co/26sTsz6XO4"=>"1", "Looking forward to reminiscing about Napster at Harvard Cyberlaw next Monday at noon with @cbavitz and the stellar folks he’s assembled. RSVP and more info here: \n\nhttps://t.co/CCR45xKy89"=>"1", "Faculty Voices: HLS Professor and @BKCHarvard Executive Director Urs Gasser discusses his work on ethics and the governance of artificial intelligence, and advising Chancellor Angela Merkel as part of the German Digital Council https://t.co/YjNu8MwjQI @ugasser"=>"1", "The only thing worse than Facebook refereeing our discourse by judging what political ads are worthy is Facebook taking no responsibility for the content of the ads they're profiting from. Or is it the other way around?\n\nOut-there thoughts on a new frame:\n\nhttps://t.co/itedTPVT19"=>"1", "Abstracts and slides of some presentations at our #disinformation workshop @BKCHarvard last month are now available online! https://t.co/TJrvODBTwn A wonderful collection of studies on the topic around the world. #disinfocon"=>"1", "The Clinic is hiring! We are especially interested in attorneys with social justice practices (inc practices that touch on race, gender, and economic issues) who have an interest in technology, even if they wouldn’t identify as tech lawyers. Details: https://t.co/50Hv1fjQq3 https://t.co/VL6W3r6TCB"=>"1", "power inequalities, ethics and technology: an essay on how power dynamics in AI ethics would define business, society, government, the lives of individuals and their access to opportunity https://t.co/DGXXOpQk18"=>"1", "What are the advantages and disadvantages of digital platform companies self-regulating? 🎥 CIGI expert and co-director of @BKCHarvard Ruth Okediji explains.\n\nLearn more about different models for platform governance by visiting https://t.co/hNYq5E5U7g https://t.co/Rf1iFGo4us"=>"1", "Lumen's staff is thrilled to announce that the project has received a $1.5 million grant from @ArcadiaFund, a charitable fund of Lisbet Rausing and Peter Baldwin, to expand and improve its database and research efforts. \nSee our full press release below\n\nhttps://t.co/Vy7gJBn3Ov"=>"1", "The @lumendatabase team could not be more excited to share this news — HUGE thanks to @ArcadiaFund for the support, to @HollandoF for his tireless work on the project, and to many others at @BKCHarvard and beyond who've been involved over the years. Much more to come! https://t.co/jTgt5TrrsW"=>"1", "We @BKCHarvard mapped Saudi Twitterspher and found a cluster populated by dissidents. They use pseudonyms and post content from websites blocked in the kingdom https://t.co/apm52em2BK https://t.co/Qi6qceLuJc"=>"1", "Wonderful to have Sandra Cortesi in Turin to speak about youth and digital media at the Festival of Technology &amp; Society ! @BKCHarvard @YouthandMedia #FesTech19 https://t.co/0juKNsiVUd"=>"1", "📸:The @HarvardJOL Symposium on Regulating Social Media wrapped up with @hbwhbwhbw, @zittrain, @jc_simons, and @JessicaFjeld discussing 💬💬💬 the future of social media regulation. 👏👏👏 https://t.co/CcIGOZ2ORf"=>"1", "Happening in 1️⃣ hour!! https://t.co/mKOqbbMtI9"=>"1", "Register now for @HarvardEthics  @dsallentess lecture, \"Human Choice in a Hyper-technological Age,\" November 21 at 5:00 PM: \n\nhttps://t.co/JeHxM4dSLe https://t.co/Kt1BHi6V5I"=>"1"}
    )
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
