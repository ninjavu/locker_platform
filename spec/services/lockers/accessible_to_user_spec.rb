require "rails_helper"

RSpec.describe Lockers::AccessibleToUser do
  it "scopes employees to their team and support to everything" do
    locker = create(:locker)
    other_locker = create(:locker)
    employee = create(:user, team: locker.team)
    support = create(:user, :support)

    expect(described_class.call(user: employee)).to contain_exactly(locker)
    expect(described_class.call(user: support)).to contain_exactly(locker, other_locker)
  end
end
