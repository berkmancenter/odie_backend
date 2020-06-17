# frozen_string_literal: true

# == Schema Information
#
# Table name: tweet_fetchers
#
#  id          :bigint           not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  data_set_id :bigint
#
# Indexes
#
#  index_tweet_fetchers_on_data_set_id  (data_set_id)
#
# Foreign Keys
#
#  fk_rails_...  (data_set_id => data_sets.id)
#

# TweetFetcher fetches tweets for a single user. One DataSet spawns many
# TweetFetchers, one per user_id in the cohort. This allows us to execute
# tweet fetching out-of-band, so that we can be sensitive to rate limits.
# When all of a DataSet's TweetFetchers are complete, the DataSet can be
# finalized.
class TweetFetcher < ApplicationRecord
  belongs_to :data_set

  def ingest
    data_set.twitter_ids.each do |user_id|
      TweetFetchingJob.set(wait: TweetFetchingJob.backoff)
                      .perform_later(data_set, user_id)
    end
  end
end
