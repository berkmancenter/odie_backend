class CreateCohortCollectors < ActiveRecord::Migration[5.2]
  def change
    create_table :cohort_collectors do |t|

      t.timestamps
    end
  end
end
