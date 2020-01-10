class CreateCohorts < ActiveRecord::Migration[5.2]
  def change
    create_table :cohorts do |t|
      t.text :twitter_ids, array: true, default: []
      t.text :description

      t.timestamps
    end
  end
end
