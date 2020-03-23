class CreateRetweets < ActiveRecord::Migration[5.2]
  def change
    create_table :retweets do |t|
      t.text :text
      t.integer :count
      t.string :link
      t.references :data_set

      t.timestamps
    end
  end
end
