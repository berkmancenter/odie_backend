class AddNameToCohorts < ActiveRecord::Migration[5.2]
  def change
    add_column :cohorts, :name, :text
  end
end
