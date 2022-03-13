ActiveRecord::Schema.define do
  create_table :products do |t|
    t.string :name
  end

  create_table :stores do |t|
    t.string :name
  end

  create_table :users do |t|
  end

  create_table :searchjoy_searches do |t|
    t.references :user
    t.string :search_type
    t.string :query
    t.string :normalized_query
    t.integer :results_count
    t.datetime :created_at
    t.references :convertable, polymorphic: true, index: {name: "index_searchjoy_searches_on_convertable"}
    t.datetime :converted_at
    t.string :source
  end
end
