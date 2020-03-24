class RemoveTopRetweetsFromDataSet < ActiveRecord::Migration[5.2]
  def change
    remove_column :data_sets, :top_retweets, :hstore
  end
end
