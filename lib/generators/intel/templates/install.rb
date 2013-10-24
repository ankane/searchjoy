class <%= migration_class_name %> < ActiveRecord::Migration
  def change
    create_table :searches do |t|
      t.string :searchable_type
      t.string :query
      t.integer :results_count
      t.timestamp :created_at
    end
  end
end
