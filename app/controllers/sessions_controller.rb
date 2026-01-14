# frozen_string_literal: true

class SessionsController < ApplicationController
  def new
    # Renders login form
  end

  def create
    user = User.active.find_by(email_address: params[:email_address])

    if user&.authenticate(params[:password])
      start_new_session_for(user)
      redirect_to after_sign_in_path, notice: "Signed in successfully"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: "Signed out successfully"
  end

  private

  def after_sign_in_path
    avo.root_path
  end
end
