class CreateDataConfigs < ActiveRecord::Migration[5.2]
  def change
    create_table :data_configs do |t|
      t.string :index_name
      t.string :keywords, array: true
      t.timestamps
    end
  end
end
