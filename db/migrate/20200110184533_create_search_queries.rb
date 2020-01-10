class CreateSearchQueries < ActiveRecord::Migration[5.2]
  def change
    create_table :search_queries do |t|

      t.timestamps
    end
  end
end
