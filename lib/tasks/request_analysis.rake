require 'rake'

namespace :odie do
  desc 'Request outstanding cohort summaries from analysis stack'
  task :get_cohort_summaries => [:environment] do |t|
    to_fetch = CohortSummary.where(results: nil)
    pbar = ProgressBar.create(total: to_fetch.count, format: '%a |%b>%i| %p%% %t %e')
    to_fetch.each do |cs|
      AnalysisStack.request_cohort_summary_results(cs)
      pbar.increment
      sleep 10
    end
  end

  desc 'Request outstanding cohort comparisons from analysis stack'
  task :get_cohort_comparisons => [:environment] do |t|
    CohortComparison.where(results: nil).each do |cc|
      AnalysisStack.request_cohort_comparison_results(cc)
    end
  end
end
