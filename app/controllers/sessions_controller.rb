class SessionsController < ApplicationController
  def update
    user = User.find(params.expect(:user_id))
    session[:user_id] = user.id
    redirect_to root_path, notice: "Now acting as #{user.label}"
  end
end
