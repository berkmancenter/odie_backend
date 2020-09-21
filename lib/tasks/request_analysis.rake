require 'rake'

namespace :odie do
  desc 'Request outstanding cohort summaries from analysis stack'
  task :get_cohort_summaries => [:environment] do |t|
    CohortSummary.where(results: nil).each do |cs|
      AnalysisStack.request_cohort_summary_results(cs)
    end
  end

  desc 'Request outstanding cohort comparisons from analysis stack'
  task :get_cohort_comparisons => [:environment] do |t|
    CohortComparison.where(results: nil).each do |cc|
      AnalysisStack.request_cohort_comparison_results(cc)
    end
  end
end
