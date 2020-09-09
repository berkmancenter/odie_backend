# == Schema Information
#
# Table name: cohort_summaries
#
#  id          :bigint           not null, primary key
#  results     :json
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  cohort_id   :bigint
#  timespan_id :bigint
#
# Indexes
#
#  index_cohort_summaries_on_cohort_id    (cohort_id)
#  index_cohort_summaries_on_timespan_id  (timespan_id)
#
# Foreign Keys
#
#  fk_rails_...  (cohort_id => cohorts.id)
#  fk_rails_...  (timespan_id => timespans.id)
#

class CohortSummarySerializer
  include FastJsonapi::ObjectSerializer
  attribute :cohort_id
  attribute :timespan_id
  attribute :results
end