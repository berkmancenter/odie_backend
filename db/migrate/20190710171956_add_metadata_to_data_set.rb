class AddMetadataToDataSet < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'hstore' unless extension_enabled?('hstore')

    add_column :data_sets, :num_users, :integer
    add_column :data_sets, :num_tweets, :integer
    add_column :data_sets, :num_retweets, :integer
    add_column :data_sets, :hashtags, :hstore, default: {}
    add_column :data_sets, :top_words, :hstore, default: {}
    add_column :data_sets, :top_urls, :hstore, default: {}
    add_column :data_sets, :top_mentions, :hstore, default: {}
    add_column :data_sets, :top_sources, :hstore, default: {}
    add_column :data_sets, :top_retweets, :hstore, default: {}
  end
end
