# frozen_string_literal: true

# == Schema Information
#
# Table name: users
# Database name: primary
#
#  id              :integer          not null, primary key
#  email_address   :string           not null
#  name            :string           not null
#  password_digest :string           not null
#  role            :string           default("editor"), not null
#  status          :string           default("active"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Email validation tests
  test "should not save user without email" do
    user = User.new(name: "Test User", password: "password123")
    assert_not user.save, "Saved user without email_address"
  end

  test "should not save user with invalid email format" do
    user = User.new(email_address: "invalid-email", name: "Test User", password: "password123")
    assert_not user.save, "Saved user with invalid email format"
  end

  test "should not save user with duplicate email" do
    User.create!(email_address: "test@example.com", name: "First User", password: "password123")
    user = User.new(email_address: "test@example.com", name: "Second User", password: "password123")
    assert_not user.save, "Saved user with duplicate email"
  end

  # Name validation tests
  test "should not save user without name" do
    user = User.new(email_address: "test@example.com", password: "password123")
    assert_not user.save, "Saved user without name"
  end

  # Password authentication tests
  test "should authenticate user with correct password" do
    user = User.create!(email_address: "test@example.com", name: "Test User", password: "password123")
    assert user.authenticate("password123"), "Failed to authenticate with correct password"
  end

  test "should not authenticate user with incorrect password" do
    user = User.create!(email_address: "test@example.com", name: "Test User", password: "password123")
    assert_not user.authenticate("wrongpassword"), "Authenticated with incorrect password"
  end

  # Default status and role tests
  test "should have active status by default" do
    user = User.create!(email_address: "test@example.com", name: "Test User", password: "password123")
    assert user.active?, "User should have active status by default"
    assert_equal "active", user.status_before_type_cast
  end

  test "should have editor role by default" do
    user = User.create!(email_address: "test@example.com", name: "Test User", password: "password123")
    assert user.editor?, "User should have editor role by default"
    assert_equal "editor", user.role_before_type_cast
  end

  # Association tests
  test "should have many sessions" do
    assert_respond_to User.new, :sessions
  end

  test "should have many bans" do
    assert_respond_to User.new, :bans
  end

  test "should destroy dependent sessions when user is destroyed" do
    user = User.create!(email_address: "test@example.com", name: "Test User", password: "password123")
    session = user.sessions.create!(token: SecureRandom.urlsafe_base64(32), last_active_at: Time.current)

    assert_difference "Session.count", -1 do
      user.destroy
    end
  end

  test "should destroy dependent bans when user is destroyed" do
    user = User.create!(email_address: "test@example.com", name: "Test User", password: "password123")
    ban = user.bans.create!(reason: "Test ban")

    assert_difference "Ban.count", -1 do
      user.destroy
    end
  end

  # Ban tests
  test "ban! records the ban, suspends the user and closes every session" do
    user = User.create!(email_address: "ban@example.com", name: "Ban Me", password: "password123")
    user.sessions.create!(token: SecureRandom.urlsafe_base64(32), last_active_at: Time.current)
    expires_at = 3.days.from_now

    user.ban!(reason: "Spamming", ip_address: "10.0.0.1", expires_at: expires_at)

    ban = user.bans.sole
    assert_equal "Spamming", ban.reason
    assert_equal "10.0.0.1", ban.ip_address
    assert_equal expires_at.to_i, ban.expires_at.to_i
    assert user.reload.banned?, "Banned user should be suspended"
    assert_equal 0, user.sessions.count, "Ban should close every session"
  end

  test "ban! without an expiry bans the user indefinitely" do
    user = User.create!(email_address: "forever@example.com", name: "Ban Me", password: "password123")

    user.ban!(reason: "Spamming")

    ban = user.bans.sole
    assert_nil ban.expires_at
    assert_nil ban.ip_address
    assert ban.active?
  end

  test "unban! expires the active bans and reactivates the user" do
    user = users(:suspended)
    ban = bans(:active_ban)

    user.unban!

    assert_not user.reload.banned?, "Unbanned user should be active again"
    assert_not ban.reload.active?, "unban! should expire the active ban"
  end
end
