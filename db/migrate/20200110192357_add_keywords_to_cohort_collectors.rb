class AddKeywordsToCohortCollectors < ActiveRecord::Migration[5.2]
  def change
    add_column :cohort_collectors, :keywords, :string
  end
end
