# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
# Database name: primary
#
#  id             :integer          not null, primary key
#  ip_address     :string
#  last_active_at :datetime         not null
#  token          :string           not null
#  user_agent     :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :integer          not null
#
# Indexes
#
#  index_sessions_on_last_active_at  (last_active_at)
#  index_sessions_on_token           (token) UNIQUE
#  index_sessions_on_user_id         (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id) ON DELETE => cascade
#
class Session < ApplicationRecord
  belongs_to :user, strict_loading: true

  before_create :generate_token
  before_create :set_last_active

  def touch_last_active
    update(last_active_at: Time.current)
  end

  def expired?
    last_active_at < 30.days.ago
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def set_last_active
    self.last_active_at ||= Time.current
  end
end
