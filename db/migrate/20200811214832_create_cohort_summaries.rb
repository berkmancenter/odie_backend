class CreateCohortSummaries < ActiveRecord::Migration[5.2]
  def change
    create_table :cohort_summaries do |t|
      t.references :cohort, foreign_key: true
      t.references :timespan, foreign_key: true
      t.json :results

      t.timestamps
    end
  end
end
