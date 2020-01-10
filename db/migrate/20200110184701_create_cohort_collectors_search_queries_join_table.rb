class CreateCohortCollectorsSearchQueriesJoinTable < ActiveRecord::Migration[5.2]
  def change
    create_join_table :cohort_collectors, :search_queries do |t|
      t.index :cohort_collector_id
      t.index :search_query_id
    end
  end
end
