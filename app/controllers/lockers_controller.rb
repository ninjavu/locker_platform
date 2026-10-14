class LockersController < ApplicationController
  before_action :set_locker, except: :index

  def index
    @lockers = accessible_lockers.includes(team: :company).order(:name)
  end

  def show
    @events = @locker.locker_events.includes(:user).recent_first
  end

  def open
    operate(:open)
  end

  def close
    operate(:close)
  end

  private

  def accessible_lockers
    Lockers::AccessibleToUser.call(user: current_user)
  end

  # Lockers are always resolved through the accessible query, so a locker
  # from another team or company is indistinguishable from a missing one (404).
  def set_locker
    @locker = accessible_lockers.find(params.expect(:id))
  end

  def operate(event)
    result = Lockers::Operate.call(locker: @locker, user: current_user, event: event)

    flash_key = result.success? ? :notice : :alert
    redirect_back fallback_location: @locker, allow_other_host: false, flash_key => result.message
  end
end
