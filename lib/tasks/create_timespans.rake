require 'rake'

namespace :odie do
  desc 'Create any timespans that are ready to be created'
  task :create_timespans => [:environment] do |t|
    day_start = 1.day.ago.midnight
    if Timespan.day_long.where(start: day_start).count == 0
       t = Timespan.create!(start: day_start, in_seconds: Timespan::DAY_DURATION)
       puts 'day'
       puts t.to_json
    end

    week_start = 1.week.ago.beginning_of_week
    if Timespan.week_long.where(start: week_start).count == 0
       t = Timespan.create!(start: week_start, in_seconds: Timespan::WEEK_DURATION)
       puts 'week'
       puts t.to_json
    end
  end

  desc 'Create cohort summaries that do not yet exist'
  task :create_cohort_summaries => [:environment] do |t|
    cohort_timespans = Set[Cohort.pluck(:id).product(Timespan.pluck(:id))]
    cohort_summaries = Set[CohortSummary.pluck(:cohort_id, :timespan_id)]
    to_create = cohort_timespans - cohort_summaries
    to_create.each do |cohort_timespan|
      CohortSummary.create(
        cohort_id: cohort_timespan[0],
        timespan_id: cohort_timespan[1])
    end
  end

  desc 'Create cohort comparisons that do not yet exist'
  task :create_cohort_comparisons => [:environment] do |t|
    cohort_timespans = Cohort.pluck(:id).product(Timespan.pluck(:id))
    cohort_timespan_pairs = cohort_timespans.product(cohort_timespans)
    cohort_timespan_pairs.each do |cohort_timespan_pair|
      CohortComparison.create(
        cohort_a_id: cohort_timespan_pair[0][0],
        timespan_a_id: cohort_timespan_pair[0][1],
        cohort_b_id: cohort_timespan_pair[1][0],
        timespan_b_id: cohort_timespan_pair[1][1])
    end
  end
end
