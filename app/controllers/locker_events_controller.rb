class LockerEventsController < ApplicationController
  def index
    @events = LockerEvent.accessible_by(current_user)
                         .includes(:user, locker: { team: :company })
                         .recent_first
  end
end
