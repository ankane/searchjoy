require_relative "test_helper"

class ControllerTest < ActionDispatch::IntegrationTest
  def test_root
    get searchjoy.root_path
    assert_response :success
  end
end
