# == Schema Information
#
# Table name: data_configs
#
#  id         :bigint           not null, primary key
#  index_name :string
#  keywords   :string           is an Array
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

class DataConfigTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
