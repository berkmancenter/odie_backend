class CreateTweetFetchers < ActiveRecord::Migration[5.2]
  def change
    create_table :tweet_fetchers do |t|
      t.references :data_set, foreign_key: true
      t.string :user_id
      t.boolean :complete, default: false
      t.integer :backoff, default: 1

      t.timestamps
    end
  end
end
