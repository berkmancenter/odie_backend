class CreateDataSets < ActiveRecord::Migration[5.2]
  def change
    create_table :data_sets do |t|
      t.belongs_to :media_source, index: true
      t.string :index_name
      t.timestamps
    end
  end
end
