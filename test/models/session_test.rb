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
require "test_helper"

class SessionTest < ActiveSupport::TestCase
  # Token auto-generation test
  test "should auto-generate token on create" do
    user = User.create!(email_address: "test@example.com", name: "Test User", password: "password123")
    session = user.sessions.create!

    assert session.token.present?, "Token was not generated"
    assert_equal 32, Base64.urlsafe_decode64(session.token).length, "Token should be 32 bytes"
  end

  # Token uniqueness test
  test "should have unique token" do
    user = User.create!(email_address: "test@example.com", name: "Test User", password: "password123")
    session1 = user.sessions.create!
    session2 = user.sessions.create!

    assert_not_equal session1.token, session2.token, "Tokens should be unique"
  end

  # last_active_at set on create test
  test "should set last_active_at on create" do
    user = User.create!(email_address: "test@example.com", name: "Test User", password: "password123")
    session = user.sessions.create!

    assert session.last_active_at.present?, "last_active_at was not set"
    assert_in_delta Time.current, session.last_active_at, 2.seconds
  end

  # touch_last_active test
  test "should update last_active_at when touched" do
    user = User.create!(email_address: "test@example.com", name: "Test User", password: "password123")
    session = user.sessions.create!
    original_time = session.last_active_at

    travel 2.hours do
      session.touch_last_active
      assert session.last_active_at > original_time, "last_active_at was not updated"
      assert_in_delta Time.current, session.last_active_at, 2.seconds
    end
  end

  # expired? test
  test "should return true when session is expired (older than 30 days)" do
    user = User.create!(email_address: "test@example.com", name: "Test User", password: "password123")
    session = user.sessions.create!

    # Set last_active_at to 31 days ago
    session.update_column(:last_active_at, 31.days.ago)

    assert session.expired?, "Session should be expired after 30 days"
  end

  test "should return false when session is not expired (within 30 days)" do
    user = User.create!(email_address: "test@example.com", name: "Test User", password: "password123")
    session = user.sessions.create!

    # Set last_active_at to 29 days ago
    session.update_column(:last_active_at, 29.days.ago)

    assert_not session.expired?, "Session should not be expired within 30 days"
  end

  # Belongs to user test
  test "should belong to user" do
    assert_respond_to Session.new, :user
  end

  # Cascade delete test
  test "should be destroyed when user is destroyed" do
    user = User.create!(email_address: "test@example.com", name: "Test User", password: "password123")
    session = user.sessions.create!

    assert_difference "Session.count", -1 do
      user.destroy
    end
  end
end
