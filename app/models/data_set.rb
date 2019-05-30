# == Schema Information
#
# Table name: data_sets
#
#  id              :bigint           not null, primary key
#  index_name      :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  media_source_id :bigint
#
# Indexes
#
#  index_data_sets_on_media_source_id  (media_source_id)
#

class DataSet < ApplicationRecord
  belongs_to :media_source

  # data set: (governs the second pass through users)
  #   - has media source
  #   - can get users who have shared a link to it
  #   - can sample a configurable number of users
  #   - can initiate data collection for those users
  #   - has an index name -- everything in that index goes with that data set
  #   - can be active -- no, that's media source

  def sample_users
    # given an index
    # find all the users in it who have linked to the media source
    # sample them
  end

  def collect_data; end

  def create_index_name; end
end
