require 'rails_helper'

Rails.application.load_tasks
Rake::Task.define_task(:environment)

describe 'odie:create_timespans' do

  before(:example) do
    Rake::Task.clear
    Rails.application.load_tasks
  end

  it 'creates daily timespan if none exist' do
    expect(Timespan.day_long.count).to eq(0)
    Rake::Task['odie:create_timespans'].invoke('2020-01-01', '2020-01-02')
    expect(Timespan.day_long.count).to eq(1)
  end

  it 'creates weekly timespan if none exist' do
    expect(Timespan.week_long.count).to eq(0)
    Rake::Task['odie:create_timespans'].invoke('2020-01-01', '2020-01-08')
    expect(Timespan.week_long.count).to eq(1)
  end

  it 'creates daily timespan if the most recent is old' do
    create(:timespan,
           start: 4.days.ago.midnight,
           in_seconds: Timespan::DAY_DURATION)
    expect(Timespan.day_long.count).to eq(1)
    Rake::Task['odie:create_timespans'].invoke
    expect(Timespan.day_long.count).to eq(2)
  end

  it 'creates weekly timespan if the most recent is old' do
    create(:timespan,
           start: 8.days.ago.midnight,
           in_seconds: Timespan::WEEK_DURATION)
    expect(Timespan.week_long.count).to eq(1)
    Rake::Task['odie:create_timespans'].invoke(8.days.ago.to_date.to_s)
    expect(Timespan.week_long.count).to eq(2)
  end

  it 'does not create daily timespan if most recent is recent enough' do
    create(:timespan,
           start: 1.day.ago.midnight,
           in_seconds: Timespan::DAY_DURATION)
    expect(Timespan.day_long.count).to eq(1)
    Rake::Task['odie:create_timespans'].invoke
    expect(Timespan.day_long.count).to eq(1)
  end

  it 'does not create weekly timespan if most recent is recent enough' do
    create(:timespan,
           start: 1.week.ago.beginning_of_week,
           in_seconds: Timespan::WEEK_DURATION)
    expect(Timespan.week_long.count).to eq(1)
    Rake::Task['odie:create_timespans'].invoke
    expect(Timespan.week_long.count).to eq(1)
  end
end

describe 'odie:create_cohort_summaries' do
  before(:example) do
    Rake::Task.clear
    Rails.application.load_tasks
  end

  it 'creates num cohorts times num timespans summaries' do
    create(:timespan)
    create(:cohort)
    expect(Timespan.day_long.count).to eq(1)
    Rake::Task['odie:create_cohort_summary'].invoke
    expect(Timespan.day_long.count).to eq(1)
  end
end
