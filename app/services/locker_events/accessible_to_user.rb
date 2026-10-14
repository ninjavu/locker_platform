module LockerEvents
  # The action log is scoped by the same rule as the lockers themselves,
  # reused via a join rather than restated.
  class AccessibleToUser < ApplicationService
    def initialize(user:)
      @user = user
    end

    def call
      LockerEvent.joins(:locker).merge(Lockers::AccessibleToUser.call(user: @user))
    end
  end
end
