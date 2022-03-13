require_relative "test_helper"

class ControllerTest < ActionDispatch::IntegrationTest
  def test_root
    get searchjoy.root_path
    assert_response :success
    assert_match "<h1>Live Stream</h1>", response.body
  end

  def test_overview
    get searchjoy.overview_searches_path(search_type: "Item")
    assert_response :success
    assert_match "Item Overview", response.body
  end

  def test_top_searches
    get searchjoy.searches_path(search_type: "Item")
    assert_response :success
    assert_match "Item Searches", response.body
  end

  def test_low_conversions
    get searchjoy.searches_path(search_type: "Item", sort: "conversion_rate")
    assert_response :success
    assert_match "Item Searches", response.body
  end
end
