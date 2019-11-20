class AddTopWordsToDataSet < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'hstore' unless extension_enabled?('hstore')
    add_column :data_sets, :top_words, :hstore, default: {}
  end
end
