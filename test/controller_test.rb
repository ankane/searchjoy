require_relative "test_helper"

class ControllerTest < ActionDispatch::IntegrationTest
  def setup
    Product.destroy_all
    Searchjoy::Search.delete_all
    Searchjoy::Conversion.delete_all
    Searchjoy::Search.create(
      search_type: "Item",
      query: "apple",
      results_count: 12,
      user_id: 1,
      source: "web"
    )
  end

  def test_root
    get searchjoy.root_path
    assert_response :success
    assert_match "<h1>Live Stream</h1>", response.body

    get searchjoy.searches_recent_path
    assert_response :success
    assert_match "less than a minute ago", response.body
  end

  def test_overview
    get searchjoy.overview_searches_path(search_type: "Item")
    assert_response :success
    assert_match "Item Overview", response.body
    assert_match "apple", response.body
  end

  def test_top_searches
    get searchjoy.searches_path(search_type: "Item")
    assert_response :success
    assert_match "Item Searches", response.body
    assert_match "Top 100", response.body
    assert_match "apple", response.body
  end

  def test_top_searches_option
    Searchjoy.stub(:top_searches, 500) do
      get searchjoy.searches_path(search_type: "Item")
      assert_response :success
      assert_match "Top 500", response.body
    end
  end

  def test_low_conversions
    get searchjoy.searches_path(search_type: "Item", sort: "conversion_rate")
    assert_response :success
    assert_match "Item Searches", response.body
    assert_match "apple", response.body
  end

  def test_time_zone
    time_zone = ActiveSupport::TimeZone.new("Pacific Time (US & Canada)")
    Searchjoy.stub(:time_zone, time_zone) do
      get searchjoy.searches_path(search_type: "Item")
      assert_response :success
      assert_match "Pacific Time", response.body
    end
  end

  def test_query_url
    query_url = lambda do |search|
      "/items?q=#{search.query}"
    end
    Searchjoy.stub(:query_url, -> { query_url }) do
      get searchjoy.searches_recent_path
      assert_response :success
      assert_match 'href="/items?q=apple"', response.body
    end
  end

  def test_query_name
    query_name = lambda do |search|
      "#{search.query} #{search.source}"
    end
    Searchjoy.stub(:query_name, -> { query_name }) do
      get searchjoy.searches_recent_path
      assert_response :success
      assert_match "apple web", response.body
    end
  end

  def test_conversion
    Searchjoy::Search.last.convert

    get searchjoy.searches_recent_path
    assert_response :success
    assert_match "Converted", response.body
  end

  def test_conversion_item
    product = Product.create!(name: "Banana")
    Searchjoy::Search.last.convert(product)

    get searchjoy.searches_recent_path
    assert_response :success
    assert_match "Product #{product.id}", response.body
  end

  def test_conversion_name
    product = Product.create!(name: "Banana")
    Searchjoy::Search.last.convert(product)

    conversion_name = lambda do |conversion|
      conversion.name
    end
    Searchjoy.stub(:conversion_name, -> { conversion_name }) do
      get searchjoy.searches_recent_path
      assert_response :success
      assert_match product.name, response.body
    end
  end

  def test_single_conversions
    Searchjoy.stub(:multiple_conversions, false) do
      product = Product.create!(name: "Banana")
      Searchjoy::Search.last.convert(product)

      get searchjoy.searches_recent_path
      assert_response :success
      assert_match "Product #{product.id}", response.body
    end
  end
end
