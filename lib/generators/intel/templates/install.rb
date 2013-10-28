class <%= migration_class_name %> < ActiveRecord::Migration
  def change
    create_table :searches do |t|
      t.string :search_type
      t.string :query
      t.integer :results_count
      t.timestamp :created_at
      t.integer :convertable_id
      t.string :convertable_type
      t.timestamp :converted_at
    end

    add_index :searches, [:created_at]
    add_index :searches, [:search_type, :created_at]
    add_index :searches, [:convertable_id, :convertable_type]
  end
end
