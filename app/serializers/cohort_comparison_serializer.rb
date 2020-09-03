# == Schema Information
#
# Table name: cohort_comparisons
#
#  id            :bigint           not null, primary key
#  results       :json
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  cohort_a_id   :bigint
#  cohort_b_id   :bigint
#  timespan_a_id :bigint
#  timespan_b_id :bigint
#
# Indexes
#
#  index_cohort_comparisons_on_cohort_a_id    (cohort_a_id)
#  index_cohort_comparisons_on_cohort_b_id    (cohort_b_id)
#  index_cohort_comparisons_on_timespan_a_id  (timespan_a_id)
#  index_cohort_comparisons_on_timespan_b_id  (timespan_b_id)
#
# Foreign Keys
#
#  fk_rails_...  (cohort_a_id => cohorts.id)
#  fk_rails_...  (cohort_b_id => cohorts.id)
#  fk_rails_...  (timespan_a_id => timespans.id)
#  fk_rails_...  (timespan_b_id => timespans.id)
#

class CohortComparisonSerializer
  include FastJsonapi::ObjectSerializer
  attribute :cohort_a_id
  attribute :timespan_a_id
  attribute :cohort_b_id
  attribute :timespan_b_id
  attribute :results
end
