class CreateTimespans < ActiveRecord::Migration[5.2]
  def change
    create_table :timespans do |t|
      t.string :name, null: false
      t.datetime :start, null: false
      t.datetime :end, null: false
      t.integer :in_seconds, null: false

      t.timestamps
    end
  end
end
