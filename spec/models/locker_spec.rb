require "rails_helper"

RSpec.describe Locker, type: :model do
  let(:team)   { create(:team) }
  let(:user)   { create(:user, team: team) }
  let(:locker) { create(:locker, team: team) }

  describe "#open!" do
    it "transitions state and records who did it" do
      expect { locker.open!(user) }.to change { locker.locker_events.count }.by(1)

      expect(locker.reload).to be_open
      event = locker.locker_events.recent_first.first
      expect(event.action).to eq("open")
      expect(event.user).to eq(user)
    end

    it "raises on an already open locker and logs nothing" do
      open_locker = create(:locker, :open, team: team)

      expect {
        expect { open_locker.open!(user) }.to raise_error(AASM::InvalidTransition)
      }.not_to change(LockerEvent, :count)
    end

    it "rolls back the state change when the audit event cannot be saved" do
      expect { locker.open!(nil) }.to raise_error(ActiveRecord::RecordInvalid)

      expect(locker.reload).to be_closed
    end

    it "fails on a stale instance instead of double-logging a concurrent open" do
      stale = described_class.find(locker.id) # second request's copy, still sees "closed"

      locker.open!(user)

      expect {
        expect { stale.open!(user) }.to raise_error(ActiveRecord::StaleObjectError)
      }.not_to change(LockerEvent, :count)
      expect(locker.reload).to be_open
    end
  end

  describe ".accessible_by" do
    it "scopes employees to their team and support to everything" do
      other_locker = create(:locker)
      support = create(:user, :support)

      expect(described_class.accessible_by(user)).to contain_exactly(locker)
      expect(described_class.accessible_by(support)).to contain_exactly(locker, other_locker)
    end
  end
end
