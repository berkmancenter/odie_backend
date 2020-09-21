class AddCohortCalcsUniqueness < ActiveRecord::Migration[5.2]
  def change
    add_index(:cohort_summaries, [:cohort_id, :timespan_id], unique: true)
    add_index(:cohort_comparisons,
              [:cohort_a_id, :timespan_a_id, :cohort_b_id, :timespan_b_id],
              unique: true,
              name: 'by_cohort_and_timespan')
  end
end
