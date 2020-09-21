# == Schema Information
#
# Table name: timespans
#
#  id         :bigint           not null, primary key
#  end        :datetime         not null
#  in_seconds :integer          not null
#  name       :string           not null
#  start      :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TimespanSerializer
  include FastJsonapi::ObjectSerializer
  attributes :name, :start, :end, :in_seconds
end
