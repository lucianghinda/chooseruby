# frozen_string_literal: true

# == Schema Information
#
# Table name: bans
# Database name: primary
#
#  id         :integer          not null, primary key
#  expires_at :datetime
#  ip_address :string
#  reason     :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#
# Indexes
#
#  index_bans_on_expires_at  (expires_at)
#  index_bans_on_ip_address  (ip_address)
#  index_bans_on_user_id     (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id) ON DELETE => cascade
#
class Ban < ApplicationRecord
  belongs_to :user, optional: true, strict_loading: true

  # Validation: at least one of user_id or ip_address must be present
  validate :user_or_ip_address_present

  # Scopes
  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :by_ip, ->(ip) { where(ip_address: ip) }

  def active?
    expires_at.nil? || expires_at > Time.current
  end

  def expired?
    !active?
  end

  private

  def user_or_ip_address_present
    if user_id.blank? && ip_address.blank?
      errors.add(:base, "Must have either user or ip_address")
    end
  end
end
