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

class Timespan < ApplicationRecord
  DAY_DURATION = ActiveSupport::Duration::SECONDS_PER_DAY - 1
  WEEK_DURATION = ActiveSupport::Duration::SECONDS_PER_WEEK - 1

  before_create :calc_span
  before_create :ensure_name

  scope :day_long, -> { where(in_seconds: DAY_DURATION) }
  scope :week_long, -> { where(in_seconds: WEEK_DURATION) }

  private

  def calc_span
    return if self.start && self.end && self.in_seconds

    if self.start && self.end
      self.in_seconds = self.end - self.start
    elsif self.start && self.in_seconds
      self.end = self.start + self.in_seconds
    elsif self.end && self.in_seconds
      self.start = self.end - self.in_seconds
    end
  end

  def ensure_name
    return unless name.nil?

    if in_seconds == DAY_DURATION
      self.name = "Day of #{start.to_date.iso8601}"
    elsif in_seconds == WEEK_DURATION
      self.name = "Week starting #{start.to_date.iso8601}"
    else
      self.name = 'Untitled'
    end
  end
end
