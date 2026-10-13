require "test_helper"

class UserSwitchingTest < ActionDispatch::IntegrationTest
  test "defaults to an employee when nobody is picked yet" do
    get lockers_path

    assert_response :success
    assert_includes response.body, "Lockers of"
  end

  test "switching to an unknown user 404s" do
    patch session_path, params: { user_id: 999_999 }

    assert_response :not_found
  end

  test "a stale session user falls back to the default employee" do
    daria = users(:daria)
    sign_in_as daria
    daria.locker_events.delete_all
    daria.destroy!

    get lockers_path

    assert_response :success
    assert_includes response.body, "Lockers of" # acting as an employee again
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
