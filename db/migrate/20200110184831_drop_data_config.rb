class DropDataConfig < ActiveRecord::Migration[5.2]
  def change
    drop_table :data_configs, force: :cascade
  end
end
