class AddHashtagsToDataSet < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'hstore' unless extension_enabled?('hstore')
    add_column :data_sets, :hashtags, :hstore, default: {}
  end
end
