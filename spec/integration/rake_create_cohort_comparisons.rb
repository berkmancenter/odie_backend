require 'rails_helper'

Rails.application.load_tasks
Rake::Task.define_task(:environment)

describe 'odie:create_cohort_comparisons' do
  before(:example) do
    Rake::Task.clear
    Rails.application.load_tasks
  end

  it 'creates (num cohorts times num timespans) choose 2 comparisons' do
    create_list(:timespan, 3)
    create_list(:cohort, 2)
    expect(CohortComparison.count).to eq(0)
    Rake::Task['odie:create_cohort_comparisons'].invoke
    expect(CohortComparison.count).to eq(15)
  end

  it 'does not create cohort comparisons if they already exist' do
    create_list(:timespan, 2)
    create_list(:cohort, 2)
    Rake::Task['odie:create_cohort_comparisons'].invoke
    expect(CohortComparison.count).to eq(6)
    create(:cohort)
    Rake::Task['odie:create_cohort_comparisons'].reenable
    Rake::Task['odie:create_cohort_comparisons'].invoke
    expect(CohortComparison.count).to eq(15)
  end
end

