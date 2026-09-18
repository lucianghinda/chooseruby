# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :set_current_user
    helper_method :current_user, :authenticated?
  end

  private

  def set_current_user
    if session = find_session_by_cookie
      Current.user = session.user
      Current.session = session
    end
  end

  # Only caller is set_current_user above - was its own
  # Authentication::SessionLookup concern in a separate file for no reason
  # (a Concern with exactly one includer doesn't need to be a Concern).
  def find_session_by_cookie
    token = cookies.signed[:session_token]
    return nil unless token

    # Eager load user to prevent N+1 queries
    session = Session.includes(:user).find_by(token: token)
    return nil unless session
    return nil if session.expired?

    # Touch last_active_at to keep session alive
    session.touch_last_active

    session
  end

  def current_user
    Current.user
  end

  def authenticated?
    current_user.present?
  end

  def require_authentication
    unless authenticated?
      redirect_to new_session_path, alert: "Please sign in to continue"
    end
  end

  def start_new_session_for(user)
    session = user.sessions.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    cookies.signed.permanent[:session_token] = {
      value: session.token,
      httponly: true,
      same_site: :lax
    }

    Current.session = session
    Current.user = user
  end

  def terminate_session
    Current.session&.destroy
    cookies.delete(:session_token)
    Current.user = nil
    Current.session = nil
  end
end
