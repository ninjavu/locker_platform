class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  helper_method :current_user

  private

  # Mock authentication (out of scope per the assignment): the "logged in"
  # user lives in the session and is switched via the header dropdown.
  # Defaults to the first employee so tenant scoping is visible right away.
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) || default_user
  end

  def default_user
    session.delete(:user_id) # drop a stale id pointing to a deleted user
    User.employee.order(:id).first
  end
end
