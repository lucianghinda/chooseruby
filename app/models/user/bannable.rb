# frozen_string_literal: true

module User::Bannable
  extend ActiveSupport::Concern

  included do
    enum :status, %w[active suspended].index_by(&:itself), default: :active
  end

  def ban!(reason:, ip_address: nil, expires_at: nil)
    transaction do
      bans.create!(reason: reason, ip_address: ip_address, expires_at: expires_at)
      suspended!
      close_all_sessions
    end
  end

  def unban!
    transaction do
      bans.active.update_all(expires_at: Time.current)
      active!
    end
  end

  def banned?
    suspended?
  end

  private

  def close_all_sessions
    sessions.destroy_all
  end
end
