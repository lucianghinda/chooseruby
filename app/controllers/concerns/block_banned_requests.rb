# frozen_string_literal: true

# Refuses requests coming from a banned ip address or from a banned user.
#
# Include this after Authentication: block_if_banned asks for the current user,
# which the authentication callback resolves from the session cookie.
module BlockBannedRequests
  extend ActiveSupport::Concern

  included do
    before_action :block_if_banned
  end

  private

  def block_if_banned
    if banned_ip? || banned_user?
      render plain: "Access denied", status: :forbidden
    end
  end

  def banned_ip?
    Ban.active.by_ip(request.remote_ip).exists?
  end

  def banned_user?
    current_user&.banned?
  end
end
