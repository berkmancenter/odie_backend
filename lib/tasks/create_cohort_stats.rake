require 'rake'

namespace :odie do
  desc 'Create cohort summaries that do not yet exist'
  task :create_cohort_summaries => [:environment] do |t|
    cohort_timespans = Cohort.pluck(:id).product(Timespan.pluck(:id)).to_set
    cohort_summaries = CohortSummary.pluck(:cohort_id, :timespan_id).to_set
    to_create = cohort_timespans - cohort_summaries
    if !Rails.env.test?
      puts "Creating #{to_create.count} cohort summaries"
    end
    to_create.to_a.each do |cohort_timespan|
      CohortSummary.create(
        cohort_id: cohort_timespan[0],
        timespan_id: cohort_timespan[1])
    end
  end

  desc 'Create cohort comparisons that do not yet exist'
  task :create_cohort_comparisons => [:environment] do |t|
    cohort_timespans = Cohort.pluck(:id).product(Timespan.pluck(:id))
    cohort_timespan_pairs = cohort_timespans.combination(2)
    if !Rails.env.test?
      puts "Ensuring existence of #{cohort_timespan_pairs.count} comparisons"
    end
	pbar = ProgressBar.create(total: cohort_timespan_pairs.count, format: '%a |%b>%i| %p%% %c/%C %t %e')
    cohort_timespan_pairs.each do |cohort_timespan_pair|
      params = {
        cohort_a_id: cohort_timespan_pair[0][0],
        timespan_a_id: cohort_timespan_pair[0][1],
        cohort_b_id: cohort_timespan_pair[1][0],
        timespan_b_id: cohort_timespan_pair[1][1]
      }
      pbar.increment
	  next unless (params[:cohort_a_id] != params[:cohort_b_id]) && (params[:timespan_a_id] == params[:timespan_b_id])
      next if CohortComparison.exists?(params)
      CohortComparison.create!(params)
    end
  end
end
