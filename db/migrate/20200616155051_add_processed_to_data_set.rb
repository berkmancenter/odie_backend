class AddProcessedToDataSet < ActiveRecord::Migration[5.2]
  def change
    add_column :data_sets, :processed, :text, array: true, default: []
  end
end
