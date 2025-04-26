require_relative "test_helper"

class TrackTest < Minitest::Test
  def setup
    if Product.destroy_all.any?
      Product.search_index.refresh
    end
    Searchjoy::Search.delete_all
    Searchjoy::Conversion.delete_all
  end

  def test_track
    store_names ["Apple", "Banana"]
    products = Product.search("APPLE", track: true)
    result_search = products.search
    assert_equal 1, Searchjoy::Search.count
    search = Searchjoy::Search.last
    assert_equal result_search, search
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
    products = Product.search("APPLE BANANA", operator: "or", track: true).to_a
    search = Searchjoy::Search.last

    conversion = search.convert(products.first)
    assert_equal search, conversion.search
    assert_equal products.first, conversion.convertable
    assert_equal search.converted_at, conversion.created_at

    conversion = search.convert(products.last)
    assert_equal search, conversion.search
    assert_equal products.last, conversion.convertable
    refute_equal search.converted_at, conversion.created_at

    assert_equal 2, Searchjoy::Conversion.count
    assert_equal 2, search.conversions.count
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

    assert_equal 2, Searchjoy::Conversion.count
  end

  def test_single_conversions
    Searchjoy.stub(:multiple_conversions, false) do
      store_names ["Apple", "Banana"]
      products = Product.search("APPLE", track: true).to_a
      search = Searchjoy::Search.last

      assert_nil search.converted_at
      assert_nil search.convertable

      assert_nil search.convert(products.first)

      assert search.converted_at
      assert_equal products.first, search.convertable

      assert_equal 0, Searchjoy::Conversion.count
    end
  end

  def test_backfill_conversions
    skip if RUBY_ENGINE == "jruby"

    store_names ["Apple", "Banana"]

    3.times do
      products = Product.search("APPLE", track: true).to_a
      search = Searchjoy::Search.last
      search.convert(products.first)
    end

    Searchjoy::Conversion.delete_all

    Searchjoy.backfill_conversions

    search = Searchjoy::Search.last
    assert_equal 1, search.conversions.count

    conversion = search.conversions.first
    assert_equal search.convertable, conversion.convertable
    assert_equal search.converted_at, conversion.created_at

    Searchjoy.backfill_conversions

    assert_equal 3, Searchjoy::Conversion.count
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

  # TODO fix for mysql2 and trilogy
  def test_long_query
    query = "APPLE" * 100
    products = Product.search(query, track: true)
    assert_equal query, products.search.query
  end

  private

  def store_names(names)
    names.each do |name|
      Product.create!(name: name)
    end
    Product.search_index.refresh
  end
end
