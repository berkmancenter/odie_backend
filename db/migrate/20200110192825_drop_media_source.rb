class DropMediaSource < ActiveRecord::Migration[5.2]
  def change
    drop_table :media_sources
  end
end
