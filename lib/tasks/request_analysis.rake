require 'rake'

namespace :odie do
  desc 'Request outstanding cohort summaries from analysis stack'
  task :get_cohort_summaries => [:environment] do |t|
    to_fetch = CohortSummary.where(results: nil)
    pbar = ProgressBar.create(total: to_fetch.count, format: '%a |%b>%i| %p%% %c/%C %t %e')
    to_fetch.each do |cs|
	  begin
        AnalysisStack.request_cohort_summary_results(cs)
	  rescue
  	  end
      pbar.increment
    end
  end

  desc 'Request outstanding cohort comparisons from analysis stack'
  task :get_cohort_comparisons => [:environment] do |t|
    #to_fetch = CohortComparison.where(results: nil, timespan_a: Timespan.day_long, timespan_b: Timespan.day_long)
    #to_fetch = CohortComparison.where(results: nil).where('timespan_a_id = timespan_b_id').where(timespan_a: Timespan.day_long)
	to_fetch = CohortComparison.where(results: nil)
    pbar = ProgressBar.create(total: to_fetch.count, format: '%a |%b>%i| %p%% %c/%C %t %e')
    to_fetch.shuffle.each do |cc|
	  begin
        AnalysisStack.request_cohort_comparison_results(cc)
	  rescue
	  end
      pbar.increment
    end
  end
end
