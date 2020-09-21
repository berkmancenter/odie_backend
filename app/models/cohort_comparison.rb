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
#  by_cohort_and_timespan                     (cohort_a_id,timespan_a_id,cohort_b_id,timespan_b_id) UNIQUE
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

class CohortComparison < ApplicationRecord
  belongs_to :cohort_a, class_name: 'Cohort'
  belongs_to :timespan_a, class_name: 'Timespan'
  belongs_to :cohort_b, class_name: 'Cohort'
  belongs_to :timespan_b, class_name: 'Timespan'
end
