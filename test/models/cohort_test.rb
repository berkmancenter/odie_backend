# == Schema Information
#
# Table name: cohorts
#
#  id          :bigint           not null, primary key
#  description :text
#  twitter_ids :text             default([]), is an Array
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'test_helper'

class CohortTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
