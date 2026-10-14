require "rails_helper"

RSpec.describe Lockers::Operate do
  let(:team)   { create(:team) }
  let(:user)   { create(:user, team: team) }
  let(:locker) { create(:locker, team: team) }

  it "transitions state and records who did it" do
    result = nil
    expect {
      result = described_class.call(locker: locker, user: user, event: :open)
    }.to change { locker.locker_events.count }.by(1)

    expect(result).to be_success
    expect(result.message).to include("now open")
    expect(locker.reload).to be_open
    event = locker.locker_events.recent_first.first
    expect(event.action).to eq("open")
    expect(event.user).to eq(user)
  end

  it "fails on an already open locker and logs nothing" do
    open_locker = create(:locker, :open, team: team)

    result = nil
    expect {
      result = described_class.call(locker: open_locker, user: user, event: :open)
    }.not_to change(LockerEvent, :count)

    expect(result).not_to be_success
    expect(result.message).to include("already open")
    expect(open_locker.reload).to be_open
  end

  it "rolls back the state change when the audit event cannot be saved" do
    expect {
      described_class.call(locker: locker, user: nil, event: :open)
    }.to raise_error(ActiveRecord::RecordInvalid)

    expect(locker.reload).to be_closed
  end

  it "fails on a stale instance instead of double-logging a concurrent open" do
    stale = Locker.find(locker.id) # second request's copy, still sees "closed"
    described_class.call(locker: locker, user: user, event: :open)

    result = nil
    expect {
      result = described_class.call(locker: stale, user: user, event: :open)
    }.not_to change(LockerEvent, :count)

    expect(result).not_to be_success
    expect(result.message).to include("someone else")
    expect(locker.reload).to be_open
  end

  it "rejects unknown events loudly" do
    expect {
      described_class.call(locker: locker, user: user, event: :destroy_all)
    }.to raise_error(ArgumentError)
  end
end
