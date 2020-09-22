require 'rails_helper'

Rails.application.load_tasks
Rake::Task.define_task(:environment)

describe 'odie:create_cohort_summaries' do
  before(:example) do
    Rake::Task.clear
    Rails.application.load_tasks
  end

  it 'creates num cohorts times num timespans summaries' do
    create_list(:timespan, 3)
    create_list(:cohort, 2)
    expect(CohortSummary.count).to eq(0)
    Rake::Task['odie:create_cohort_summaries'].invoke
    expect(CohortSummary.count).to eq(6)
  end

  it 'does not create cohort summaries if they already exist' do
    create_list(:timespan, 3)
    create(:cohort)
    Rake::Task['odie:create_cohort_summaries'].invoke
    expect(CohortSummary.count).to eq(3)
    create(:cohort)
    Rake::Task['odie:create_cohort_summaries'].reenable
    Rake::Task['odie:create_cohort_summaries'].invoke
    expect(CohortSummary.count).to eq(6)
  end
end

