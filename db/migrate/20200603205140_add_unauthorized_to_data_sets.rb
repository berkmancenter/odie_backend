class AddUnauthorizedToDataSets < ActiveRecord::Migration[5.2]
  def change
    add_column :data_sets, :unauthorized, :text, array: true, default: []
  end
end
