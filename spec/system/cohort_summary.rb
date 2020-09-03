require 'rails_helper'

describe 'cohort_summary' do
  it 'responds with results' do
    ts = create(:timespan,
                start: DateTime.new(2020,7,14,0,0,0,'-05:00'),
                end: DateTime.new(2020,7,14,23,59,59,'-05:00'))
    cs = create(:cohort_summary, timespan: ts)
    AnalysisStack.request_cohort_summary_results(cs)
    while cs.results.nil?
      sleep 1
      puts 'here'
      cs.reload
    end
    visit "/cohort/#{cs.cohort_id}/timespan/#{cs.timespan_id}"
    expect(JSON.parse(page.body).dig(
      'data', 'attributes', 'results', 'n_tweets')).to eq(44)
  end
end
