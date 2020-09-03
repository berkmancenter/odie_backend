require 'rails_helper'

describe Timespan do
  it "calculates a duration if it's missing" do
    now = DateTime.current
    t = Timespan.create!(start: 2.days.before(now), end: 1.day.before(now))
    expect(t.in_seconds).to eq(ActiveSupport::Duration::SECONDS_PER_DAY)
  end

  it "calculates the end if it's missing" do
    now = DateTime.current
    t = Timespan.create!(start: 2.days.before(now),
                         in_seconds: Timespan::DAY_DURATION)
    expect(t.end).to eq(2.days.before(now) + Timespan::DAY_DURATION.seconds)
  end

  it 'can find day long timespans' do
    create(:timespan, start: DateTime.current, in_seconds: Timespan::DAY_DURATION)
    expect(Timespan.day_long.count).to eq(1)
  end

  it 'can find week long timespans' do
    create(:timespan, start: DateTime.current, in_seconds: Timespan::WEEK_DURATION)
    expect(Timespan.week_long.count).to eq(1)
  end
end
