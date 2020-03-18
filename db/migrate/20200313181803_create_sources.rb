class CreateSources < ActiveRecord::Migration[5.2]
  def change
    create_table :sources do |t|
      t.string :canonical_host
      t.string :variant_hosts, array: true

      t.timestamps
    end

    add_index :sources, :canonical_host, unique: true
    add_index :sources, :variant_hosts, using: :gin
  end
end
