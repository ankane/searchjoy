require_relative "test_helper"

class SearchjoyTest < Minitest::Test
  def setup
    if Product.destroy_all.any?
      Product.search_index.refresh
    end
    Searchjoy::Search.destroy_all
  end

  def test_track
    store_names ["Apple", "Banana"]
    products = Product.search("APPLE", track: true)
    products.to_a
    assert_equal 1, Searchjoy::Search.count
    search = Searchjoy::Search.last
    assert_equal products.search, search
    assert_equal "Product", search.search_type
    assert_equal "APPLE", search.query
    assert_equal "apple", search.normalized_query
    assert_equal 1, search.results_count
  end

  def test_models
    Searchkick.search("APPLE", models: [Product, Store], track: true).to_a
    assert_equal 1, Searchjoy::Search.count
    search = Searchjoy::Search.last
    assert_equal "Product Store", search.search_type
  end

  def test_index_name
    Searchkick.search("APPLE", index_name: [Product, Store], track: true).to_a
    assert_equal 1, Searchjoy::Search.count
    search = Searchjoy::Search.last
    assert_equal "Product Store", search.search_type
  end

  def test_all_indices
    Searchkick.search("APPLE", track: true).to_a
    assert_equal 1, Searchjoy::Search.count
    search = Searchjoy::Search.last
    assert_equal "All Indices", search.search_type
  end

  def test_user
    user = User.create!
    Product.search("APPLE", track: {user: user}).to_a
    search = Searchjoy::Search.last
    assert_equal user, search.user
  end

  def test_additional_attributes
    Product.search("APPLE", track: {source: "web"}).to_a
    search = Searchjoy::Search.last
    assert_equal "web", search.source
  end

  def test_override_attributes
    Product.search("APPLE", track: {search_type: "Item"}).to_a
    search = Searchjoy::Search.last
    assert_equal "Item", search.search_type
  end

  def test_convert
    store_names ["Apple", "Banana"]
    products = Product.search("APPLE", track: true).to_a
    search = Searchjoy::Search.last

    assert_nil search.converted_at
    assert_nil search.convertable

    search.convert(products.first)

    assert search.converted_at
    assert_equal products.first, search.convertable
  end

  def test_convert_once
    store_names ["Apple", "Banana"]
    products = Product.search("APPLE", track: true).to_a
    search = Searchjoy::Search.last

    # first convert
    search.convert
    assert search.converted?
    assert_nil search.convertable

    # should not update
    search.convert(products.first)
    assert_nil search.convertable
  end

  def test_no_track
    Product.search("apple").to_a
    assert_equal 0, Searchjoy::Search.count
  end

  def test_multi_search
    execute_options = Searchkick::VERSION.to_i >= 5 ? {} : {execute: false}
    query = Product.search("APPLE", track: true, **execute_options)
    query2 = Store.search("APPLE", track: true, **execute_options)
    assert_equal 0, Searchjoy::Search.count
    Searchkick.multi_search([query, query2])
    assert_equal 2, Searchjoy::Search.count
    assert_equal "Product", query.search.search_type
    assert_equal "Store", query2.search.search_type
  end

  private

  def store_names(names)
    names.each do |name|
      Product.create!(name: name)
    end
    Product.search_index.refresh
  end
end
