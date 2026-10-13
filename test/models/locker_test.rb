require "test_helper"

class LockerTest < ActiveSupport::TestCase
  test "open! transitions state and records who did it" do
    locker = lockers(:amazon_night_locker)

    assert_difference -> { locker.locker_events.count }, 1 do
      locker.open!(users(:alice))
    end

    assert locker.reload.open?
    event = locker.locker_events.recent_first.first
    assert_equal "open", event.action
    assert_equal users(:alice), event.user
  end

  test "open! on an open locker raises and logs nothing" do
    locker = lockers(:dpd_locker)

    assert_no_difference -> { LockerEvent.count } do
      assert_raises(AASM::InvalidTransition) { locker.open!(users(:daria)) }
    end
  end

  test "state change rolls back when the audit event cannot be saved" do
    locker = lockers(:amazon_night_locker)

    assert_raises(ActiveRecord::RecordInvalid) { locker.open!(nil) }

    assert locker.reload.closed?
  end

  test "concurrent transition on a stale instance fails instead of double-logging" do
    locker = lockers(:amazon_night_locker)
    stale = Locker.find(locker.id) # second request's copy, still sees "closed"

    locker.open!(users(:alice))

    assert_no_difference -> { LockerEvent.count } do
      assert_raises(ActiveRecord::StaleObjectError) { stale.open!(users(:alice)) }
    end
    assert locker.reload.open?
  end

  test "accessible_by scopes employees to their team and support to everything" do
    assert_equal [ lockers(:amazon_night_locker) ], Locker.accessible_by(users(:alice)).to_a
    assert_equal Locker.count, Locker.accessible_by(users(:support)).count
  end
end
