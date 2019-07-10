class AddNumTweetsToDataSet < ActiveRecord::Migration[5.2]
  def change
    add_column :data_sets, :num_tweets, :integer
  end
end
