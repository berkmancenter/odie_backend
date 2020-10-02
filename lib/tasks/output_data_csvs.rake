require 'rake'
require 'csv'

def cc_to_csv_rows(cc)
	rows = []
	rows << [
		"#{cc.cohort_a.name} - #{cc.timespan_a.name} Num Accounts",
		"#{cc.cohort_a.name} - #{cc.timespan_a.name} Num Tweets",
		"#{cc.cohort_a.name} - #{cc.timespan_a.name} Most Distinguishing N-grams",
		"#{cc.cohort_a.name} - #{cc.timespan_a.name} Top Unigrams",
		"#{cc.cohort_a.name} - #{cc.timespan_a.name} Unigram Num Accounts",
		"#{cc.cohort_a.name} - #{cc.timespan_a.name} Top Bigrams",
		"#{cc.cohort_a.name} - #{cc.timespan_a.name} Bigram Num Accounts",
		"#{cc.cohort_a.name} - #{cc.timespan_a.name} Top Trigrams",
		"#{cc.cohort_a.name} - #{cc.timespan_a.name} Trigram Num Accounts",
		"#{cc.cohort_b.name} - #{cc.timespan_b.name} Num Accounts",
		"#{cc.cohort_b.name} - #{cc.timespan_b.name} Num Tweets",
		"#{cc.cohort_b.name} - #{cc.timespan_b.name} Most Distinguishing N-grams",
		"#{cc.cohort_b.name} - #{cc.timespan_b.name} Top Unigrams",
		"#{cc.cohort_b.name} - #{cc.timespan_b.name} Unigram Num Accounts",
		"#{cc.cohort_b.name} - #{cc.timespan_b.name} Top Bigrams",
		"#{cc.cohort_b.name} - #{cc.timespan_b.name} Bigram Num Accounts",
		"#{cc.cohort_b.name} - #{cc.timespan_b.name} Top Trigrams",
		"#{cc.cohort_b.name} - #{cc.timespan_b.name} Trigram Num Accounts"
	]
	(0..49).each do |i|
		row = []
		if i == 0
			row << cc.results['summary_a']['n_accounts']
			row << cc.results['summary_a']['n_tweets']
		else
			row << nil
			row << nil
		end
		row << cc.results['f1_scores']['most_characteristic_a'][i]
		row << cc.results['summary_a']['top_unigrams'].keys[i]
		row << cc.results['summary_a']['top_unigrams'].values[i]
		row << cc.results['summary_a']['top_bigrams'].keys[i]
		row << cc.results['summary_a']['top_bigrams'].values[i]
		row << cc.results['summary_a']['top_trigrams'].keys[i]
		row << cc.results['summary_a']['top_trigrams'].values[i]
		if i == 0
			row << cc.results['summary_b']['n_accounts']
			row << cc.results['summary_b']['n_tweets']
		else
			row << nil
			row << nil
		end
		row << cc.results['f1_scores']['most_characteristic_b'][i]
		row << cc.results['summary_b']['top_unigrams'].keys[i]
		row << cc.results['summary_b']['top_unigrams'].values[i]
		row << cc.results['summary_b']['top_bigrams'].keys[i]
		row << cc.results['summary_b']['top_bigrams'].values[i]
		row << cc.results['summary_b']['top_trigrams'].keys[i]
		row << cc.results['summary_b']['top_trigrams'].values[i]
		rows << row
	end
	return rows
end

namespace :odie do
    desc 'Output existing cohort comparisons as CSVs'
    task :output_cohort_comparisons => [:environment] do |t|
        to_output = CohortComparison.where('results IS NOT NULL')
        pbar = ProgressBar.create(total: to_output.count, format: '%a |%b>%i| %p%% %c/%C %t %e')
        to_output.each do |cc|
            output_dir = Rails.root.join('tmp', 'cohort_comparisons', cc.cohort_a.name, cc.timespan_a.name)
			FileUtils.mkdir_p output_dir
            filename = output_dir.join(
				"#{cc.cohort_a.name} over #{cc.timespan_a.name} vs. #{cc.cohort_b.name} over #{cc.timespan_b.name}.csv")
            CSV.open(filename, 'wb') do |csv|
				cc_to_csv_rows(cc).each do |row|
					csv << row
				end
            end
            pbar.increment
        end
    end
end
