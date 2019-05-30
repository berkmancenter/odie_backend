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

require 'test_helper'

class DataSetTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
