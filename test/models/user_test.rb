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

  # Bannable tests
  test "ban! suspends the user, records the ban and closes sessions" do
    user = User.create!(email_address: "test@example.com", name: "Test User", password: "password123")
    session = user.sessions.create!

    user.ban!(reason: "Spam", ip_address: "127.0.0.1")

    assert user.banned?
    assert user.suspended?
    assert_equal "Spam", user.bans.sole.reason
    assert_equal "127.0.0.1", user.bans.sole.ip_address
    assert_not Session.exists?(session.id)
  end

  test "unban! reactivates the user and expires active bans" do
    user = User.create!(email_address: "test@example.com", name: "Test User", password: "password123")
    user.ban!(reason: "Spam")

    user.unban!

    assert_not user.banned?
    assert user.active?
    assert_empty user.bans.active
  end

  # Role tests
  test "can_administer? is true only for admins" do
    admin = User.new(email_address: "admin@example.com", name: "Admin", password: "password123", role: :admin)
    editor = User.new(email_address: "editor@example.com", name: "Editor", password: "password123", role: :editor)

    assert admin.can_administer?
    assert_not editor.can_administer?
  end
end
