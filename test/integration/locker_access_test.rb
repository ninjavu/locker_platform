require "test_helper"

# The core requirement of the assignment: data separation between companies
# and teams must really work, for reads and for open/close actions alike.
class LockerAccessTest < ActionDispatch::IntegrationTest
  test "employee sees only their team's lockers on the list" do
    sign_in_as users(:alice)
    get lockers_path

    assert_response :success
    assert_includes response.body, "AMZ-N-01"
    assert_not_includes response.body, "AMZ-D-01" # other team, same company
    assert_not_includes response.body, "DPD-N-01" # other company
  end

  test "employee can view their team's locker page with its history" do
    sign_in_as users(:alice)
    get locker_path(lockers(:amazon_night_locker))

    assert_response :success
    assert_includes response.body, "Action history"
  end

  test "employee gets 404 for a locker of another team in the same company" do
    sign_in_as users(:alice)
    get locker_path(lockers(:amazon_day_locker))

    assert_response :not_found
  end

  test "employee gets 404 for a locker of another company" do
    sign_in_as users(:alice)
    get locker_path(lockers(:dpd_locker))

    assert_response :not_found
  end

  test "employee can open and close their team's locker, actions are logged" do
    locker = lockers(:amazon_night_locker)
    sign_in_as users(:alice)

    assert_difference -> { locker.locker_events.count }, 2 do
      post open_locker_path(locker)
      assert_response :redirect
      assert locker.reload.open?

      post close_locker_path(locker)
      assert_response :redirect
      assert locker.reload.closed?
    end

    assert_equal [ "close", "open" ], locker.locker_events.recent_first.limit(2).pluck(:action)
    assert_equal users(:alice), locker.locker_events.recent_first.first.user
  end

  test "employee cannot operate a locker of another team or company" do
    sign_in_as users(:alice)

    [ lockers(:amazon_day_locker), lockers(:dpd_locker) ].each do |locker|
      [ open_locker_path(locker), close_locker_path(locker) ].each do |path|
        state_before = locker.state

        assert_no_difference -> { LockerEvent.count } do
          post path
        end

        assert_response :not_found
        assert_equal state_before, locker.reload.state
      end
    end
  end

  test "opening an already open locker redirects with an alert and logs nothing" do
    locker = lockers(:dpd_locker) # open in fixtures
    sign_in_as users(:daria)

    assert_no_difference -> { LockerEvent.count } do
      post open_locker_path(locker)
    end

    assert_redirected_to locker_path(locker)
    assert locker.reload.open?
    follow_redirect!
    assert_includes response.body, "already open"
  end

  test "support engineer sees every locker on the platform" do
    sign_in_as users(:support)
    get lockers_path

    assert_response :success
    [ "AMZ-N-01", "AMZ-D-01", "DPD-N-01" ].each { |name| assert_includes response.body, name }
  end

  test "support engineer can operate any locker" do
    locker = lockers(:amazon_day_locker)
    sign_in_as users(:support)

    post open_locker_path(locker)

    assert_response :redirect
    assert locker.reload.open?
    assert_equal users(:support), locker.locker_events.recent_first.first.user
  end
end
