require 'rails_helper'

describe 'cohort_comparison' do
  it 'responds with results' do
    ts_a = create(:timespan,
                start: DateTime.new(2020,7,14,0,0,0,'-05:00'),
                end: DateTime.new(2020,7,14,23,59,59,'-05:00'))
    ts_b = create(:timespan,
                start: DateTime.new(2019,8,1,0,0,0,'-05:00'),
                end: DateTime.new(2020,8,1,23,59,59,'-05:00'))
    cc = create(:cohort_comparison, timespan_a: ts_a, timespan_b: ts_b)
    AnalysisStack.request_cohort_comparison_results(cc)
    while cc.results.nil?
      sleep 1
      puts 'sleeping'
      cc.reload
    end
    visit "/cohort/#{cc.cohort_a_id}/timespan/#{cc.timespan_a_id}"\
          "/cohort/#{cc.cohort_b_id}/timespan/#{cc.timespan_b_id}"
    expect(JSON.parse(page.body).dig(
      'data', 'attributes', 'results', 'n_tweets')).to eq(44)
  end
end

