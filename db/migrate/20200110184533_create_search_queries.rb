class CreateSearchQueries < ActiveRecord::Migration[5.2]
  def change
    create_table :search_queries do |t|
      t.boolean :active
      t.text :description
      t.string :keyword
      t.string :name
      t.string :url

      t.timestamps
    end
  end
end
