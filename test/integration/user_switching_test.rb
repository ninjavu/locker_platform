require "test_helper"

class UserSwitchingTest < ActionDispatch::IntegrationTest
  test "defaults to an employee when nobody is picked yet" do
    get lockers_path

    assert_response :success
    assert_includes response.body, "Lockers of"
  end

  test "switching user changes what the list shows" do
    sign_in_as users(:alice)
    get lockers_path
    assert_not_includes response.body, "DPD-N-01"

    sign_in_as users(:daria)
    get lockers_path
    assert_includes response.body, "DPD-N-01"
    assert_not_includes response.body, "AMZ-N-01"
  end
end
