class CreateCohortComparisons < ActiveRecord::Migration[5.2]
  def change
    create_table :cohort_comparisons do |t|
      t.references :cohort_a, foreign_key: {to_table: :cohorts}
      t.references :timespan_a, foreign_key: {to_table: :timespans}
      t.references :cohort_b, foreign_key: {to_table: :cohorts}
      t.references :timespan_b, foreign_key: {to_table: :timespans}
      t.json :results

      t.timestamps
    end
  end
end
