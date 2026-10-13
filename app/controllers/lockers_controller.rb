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
    Locker.accessible_by(current_user)
  end

  # Lockers are always resolved through the accessible scope, so a locker
  # from another team or company is indistinguishable from a missing one (404).
  def set_locker
    @locker = accessible_lockers.find(params.expect(:id))
  end

  def operate(event)
    @locker.public_send(:"#{event}!", current_user)
    redirect_back fallback_location: @locker, notice: "Locker #{@locker.name} is now #{@locker.state}."
  rescue AASM::InvalidTransition
    redirect_back fallback_location: @locker,
                  alert: "Locker #{@locker.name} is already #{@locker.state} — nothing to do."
  end
end
