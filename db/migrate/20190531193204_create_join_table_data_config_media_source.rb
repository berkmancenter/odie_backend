class CreateJoinTableDataConfigMediaSource < ActiveRecord::Migration[5.2]
  def change
    create_join_table :data_configs, :media_sources do |t|
      t.index [:data_config_id, :media_source_id]
      t.index [:media_source_id, :data_config_id]
    end
  end
end
