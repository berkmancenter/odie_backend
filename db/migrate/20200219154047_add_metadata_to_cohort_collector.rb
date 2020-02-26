class AddMetadataToCohortCollector < ActiveRecord::Migration[5.2]
  def change
    add_column :cohort_collectors, :start_time, :datetime
    add_column :cohort_collectors, :end_time, :datetime
    add_column :cohort_collectors, :keywords, :text, array: true, default: []
  end
end
