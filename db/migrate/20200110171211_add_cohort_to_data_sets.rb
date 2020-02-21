class AddCohortToDataSets < ActiveRecord::Migration[5.2]
  def change
    add_reference :data_sets, :cohort, foreign_key: true
    remove_reference :data_sets, :media_source
  end
end
