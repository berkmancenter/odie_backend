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

require 'rails_helper'

describe TweetFetcher do
  let(:tf) { create(:tweet_fetcher, user_id: 1) }

  # TODO: replace with stuff just about TF
end
