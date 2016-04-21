require_relative "test_helper"

class SearchjoyTest < Minitest::Test
  def test_must_respond_to_top_searches
    assert_respond_to Searchjoy, :top_searches
  end

  def test_must_respond_to_conversion_name
    assert_respond_to Searchjoy, :conversion_name
  end

  def test_must_respond_to_time_zone
    assert_respond_to Searchjoy, :time_zone
  end
end
