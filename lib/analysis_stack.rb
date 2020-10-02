module AnalysisStack
  def self.request_cohort_summary_results(cs)
    params = {
      cohort_prefix: cs.cohort.index_prefix,
      timespan_start: cs.timespan.start.iso8601,
      timespan_end: cs.timespan.end.iso8601,
      post_to: Rails.application.routes.url_helpers.cohort_summary_receiver_url(
        cs.cohort_id, cs.timespan_id,
        protocol: ENV['PROTOCOL'], host: ENV['HOST'], port: ENV['PORT'],
        format: 'json')
    }
    submit_analysis_request('cohort_summary', params)
  end

  def self.request_cohort_comparison_results(cc)
    params = {
      cohort_prefix_a: cc.cohort_a.index_prefix,
      timespan_a_start: cc.timespan_a.start.iso8601,
      timespan_a_end: cc.timespan_a.end.iso8601,
      cohort_prefix_b: cc.cohort_b.index_prefix,
      timespan_b_start: cc.timespan_b.start.iso8601,
      timespan_b_end: cc.timespan_b.end.iso8601,
      post_to: Rails.application.routes.url_helpers.cohort_comparison_receiver_url(
        cc.cohort_a_id, cc.timespan_a_id,
        cc.cohort_b_id, cc.timespan_b_id,
        protocol: ENV['PROTOCOL'], host: ENV['HOST'], port: ENV['PORT'],
        format: 'json')
    }
    submit_analysis_request('cohort_comparison', params)
  end

  private

  def self.submit_analysis_request(path, params)
    request_url = ENV['ANALYSIS_HOST'] + path
    response = HTTParty.get(
      request_url,
      query: params,
	  timeout: 300
    )
    if response.code < 200 || response.code > 299
      raise "#{response.code} from analysis stack server"
    end
  end
end
