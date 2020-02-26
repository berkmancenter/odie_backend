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

  factory :cohort do
    twitter_ids { [14706139] }  # @BKCHarvard's twitter id
    description { 'Berkman Klein Center for Internet & Society' }
  end

  factory :cohort_collector do
    transient do
      queries_count { 1 }
    end

    after :build do |cc, evaluator|
      cc.search_queries = build_list(:search_query, evaluator.queries_count)
    end

    trait :with_times do
      start_time { Time.utc(1970, 01, 01) }
      end_time { Time.utc(1970, 01, 01) + 1.hour }
    end

    trait :with_keywords do
      keywords { ['cats'] }
    end

    trait :creation_permissible do
      start_time { Time.now - 20.minutes }
      end_time { Time.now - 10.minutes }
      keywords { ['exist'] }
    end
  end

  factory :data_set do
    cohort

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

  factory :search_query do
    description { 'Democracy dies in darkness' }
    name { 'WaPo' }
    url { 'https://www.washingtonpost.com' }
  end
end
