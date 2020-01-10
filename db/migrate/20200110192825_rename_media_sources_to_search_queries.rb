class RenameMediaSourcesToSearchQueries < ActiveRecord::Migration[5.2]
  def change
    rename_table :media_sources, :search_queries
  end
end
