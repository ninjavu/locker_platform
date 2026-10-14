module Lockers
  # The tenancy boundary of the app: every locker read goes through this
  # query, so a record outside the user's reach is a plain 404. Support
  # engineers see the whole platform; employees see their team's lockers.
  class AccessibleToUser < ApplicationService
    def initialize(user:)
      @user = user
    end

    def call
      @user.support? ? Locker.all : Locker.where(team_id: @user.team_id)
    end
  end
end
