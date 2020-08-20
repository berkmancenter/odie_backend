# == Schema Information
#
# Table name: timespans
#
#  id         :bigint           not null, primary key
#  end        :datetime
#  name       :string
#  start      :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Timespan < ApplicationRecord
end
