class AddDataConfigIdToDataSet < ActiveRecord::Migration[5.2]
  def change
    add_reference :data_sets, :data_config, foreign_key: true
  end
end
