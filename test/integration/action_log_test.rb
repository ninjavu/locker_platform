require "test_helper"

class ActionLogTest < ActionDispatch::IntegrationTest
  test "employee sees only events of their team's lockers" do
    sign_in_as users(:alice)
    get action_log_path

    assert_response :success
    assert_includes response.body, "AMZ-N-01"
    assert_not_includes response.body, "DPD-N-01"
  end

  test "support engineer sees events across all companies" do
    sign_in_as users(:support)
    get action_log_path

    assert_response :success
    assert_includes response.body, "AMZ-N-01"
    assert_includes response.body, "DPD-N-01"
  end
end
