require_relative "test_helper"

class SearchjoyTest < Minitest::Test
  def setup
    Product.destroy_all
    Searchjoy::Search.destroy_all
  end

  def test_track
    store_names ["Apple", "Banana"]
    products = Product.search("APPLE", track: true)
    assert_equal 1, Searchjoy::Search.count
    search = Searchjoy::Search.last
    assert_equal products.search, search
    assert_equal "Product", search.search_type
    assert_equal "APPLE", search.query
    assert_equal "apple", search.normalized_query
    assert_equal 1, search.results_count
  end

  def test_models
    Searchkick.search("APPLE", models: [Product, Store], track: true)
    assert_equal 1, Searchjoy::Search.count
    search = Searchjoy::Search.last
    assert_equal "Product Store", search.search_type
  end

  def test_index_name
    Searchkick.search("APPLE", index_name: [Product, Store], track: true)
    assert_equal 1, Searchjoy::Search.count
    search = Searchjoy::Search.last
    assert_equal "Product Store", search.search_type
  end

  def test_all_indices
    Searchkick.search("APPLE", track: true)
    assert_equal 1, Searchjoy::Search.count
    search = Searchjoy::Search.last
    assert_equal "All Indices", search.search_type
  end

  def test_user
    user = User.create!
    Product.search("APPLE", track: {user: user})
    search = Searchjoy::Search.last
    assert_equal user, search.user
  end

  def test_additional_attributes
    Product.search("APPLE", track: {source: "web"})
    search = Searchjoy::Search.last
    assert_equal "web", search.source
  end

  def test_override_attributes
    Product.search("APPLE", track: {search_type: "Item"})
    search = Searchjoy::Search.last
    assert_equal "Item", search.search_type
  end

  def test_convert
    store_names ["Apple", "Banana"]
    products = Product.search("APPLE", track: true)
    search = Searchjoy::Search.last

    assert_nil search.converted_at
    assert_nil search.convertable

    search.convert(products.first)

    assert search.converted_at
    assert_equal products.first, search.convertable
  end

  def test_convert_once
    store_names ["Apple", "Banana"]
    products = Product.search("APPLE", track: true)
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
    Product.search("apple")
    assert_equal 0, Searchjoy::Search.count
  end

  def test_multi_search
    query = Product.search("APPLE", track: true, execute: false)
    assert_equal 0, Searchjoy::Search.count
    Searchkick.multi_search([query])
    assert_equal 0, Searchjoy::Search.count
  end

  private

  def store_names(names)
    names.each do |name|
      Product.create!(name: name)
    end
    Product.search_index.refresh
  end
end
