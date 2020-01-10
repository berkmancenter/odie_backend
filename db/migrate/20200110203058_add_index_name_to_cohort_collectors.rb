class AddIndexNameToCohortCollectors < ActiveRecord::Migration[5.2]
  def change
    add_column :cohort_collectors, :index_name, :string
  end
end
