FactoryBot.define do
  sequence :email do |n|
    "user#{n}@example.com"
  end

  factory :user do
    email
    admin { false }

    trait :admin do
      admin { true }
    end
  end

  factory :media_source do
    description { 'Democracy Dies in Darkness' }
    name { 'WaPo' }
    url { 'www.washingtonpost.com' }

    trait :active do
      active { true }
    end

    trait :inactive do
      active { false }
    end

    # Just for fun...
    # https://en.wikipedia.org/wiki/List_of_defunct_newspapers_of_the_United_States#Massachusetts
    trait :evening_traveler do
      description { 'The Boston Evening Traveler was a daily paper designed ' \
                   'to be read around the family fireplace and covering a ' \
                   'variety of topics. It opposed the expansion of ' \
                   'slavery. It was absorbed by the Herald in 1912.' }
      name { 'Boston Evening Traveler' }
      url { 'https://www.bostonherald.com' }
    end

    trait :spy do
      description { 'A heavily political weekly paper constantly on the ' \
                   'verge of being suppressed by the Royalist government.' }
      name { 'Massachusetts Spy' }
      url { 'https://www.mass.spy' }
    end

    trait :phoenix do
      description { 'alternative weekly known for arts coverage' }
      name { 'Boston Phoenix' }
      url { 'www.phoenix.com' }
    end

    trait :liberator do
      description { 'abolitionist, feminist paper with influential readership' }
      name { 'The Liberator' }
      url { 'www.hellyeahgrimkésisters.org' }
    end

    trait :publick do
      description { 'The first multi-page newspaper published in the Americas' }
      name { 'Publick Occurrences Both Forreign and Domestick' }
      url { 'https://www.publick-occurrences.com' }
    end

    trait :poft_boy do
      description { 'Published by Authority (!)' }
      name { 'Bofton Weekly Poft-Boy' }
      url { 'ellis.huske.com' }
    end
  end

  factory :data_config do
    transient do
      media_sources_count { 2 }
    end

    before(:create) do |data_config, evaluator|
      data_config.media_sources << create_list(
        :media_source,
        evaluator.media_sources_count
      )
    end
  end

  factory :data_set do
    before(:create) do |ds, evaluator|
      dc = create(:data_config)
      ds.data_config = dc
      ds.media_source = dc.media_sources.first
    end

    num_users { 100 }
    num_tweets { 200 }
    num_retweets { 10 }
    top_mentions { { 'plato'=>'5', 'aristotle'=>'7' } }
    top_retweets { { 'first tweet text'=>'2', 'second tweet text'=>'3'} }
    top_sources { { 'godeysladysbook.com'=>'7', 'twitter.com'=>'4' } }
    top_urls { { 'www.cnn.com/a_story'=>'4', 'http://bitly.com/98K8eH'=>'8'} }
    top_words { { 'stopword'=>'5', 'moose'=>'74' } }
    hashtags { { 'llamas'=>'7', 'octopodes'=>'24' } }
  end
end
