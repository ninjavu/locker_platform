class LockerEventsController < ApplicationController
  def index
    @events = LockerEvents::AccessibleToUser.call(user: current_user)
                                            .includes(:user, locker: { team: :company })
                                            .recent_first
  end
end
