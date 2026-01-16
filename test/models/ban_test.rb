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
require "test_helper"

class BanTest < ActiveSupport::TestCase
  # Validation tests
  test "should not save ban without user_id or ip_address" do
    ban = Ban.new(reason: "Test ban")
    assert_not ban.save, "Saved ban without user_id or ip_address"
  end

  test "should save ban with user_id only" do
    user = User.create!(email_address: "test@example.com", name: "Test User", password: "password123")
    ban = Ban.new(user: user, reason: "Test ban")
    assert ban.save, "Did not save ban with user_id"
  end

  test "should save ban with ip_address only" do
    ban = Ban.new(ip_address: "192.168.1.100", reason: "Test ban")
    assert ban.save, "Did not save ban with ip_address"
  end

  test "should save ban with both user_id and ip_address" do
    user = User.create!(email_address: "test@example.com", name: "Test User", password: "password123")
    ban = Ban.new(user: user, ip_address: "192.168.1.100", reason: "Test ban")
    assert ban.save, "Did not save ban with both user_id and ip_address"
  end

  # active? tests
  test "should be active when expires_at is nil" do
    ban = Ban.create!(ip_address: "192.168.1.100", reason: "Test ban", expires_at: nil)
    assert ban.active?, "Ban with nil expires_at should be active"
  end

  test "should be active when expires_at is in the future" do
    ban = Ban.create!(ip_address: "192.168.1.100", reason: "Test ban", expires_at: 1.day.from_now)
    assert ban.active?, "Ban with future expires_at should be active"
  end

  test "should not be active when expires_at is in the past" do
    ban = Ban.create!(ip_address: "192.168.1.100", reason: "Test ban", expires_at: 1.day.ago)
    assert_not ban.active?, "Ban with past expires_at should not be active"
  end

  # expired? tests
  test "should be expired when expires_at is in the past" do
    ban = Ban.create!(ip_address: "192.168.1.100", reason: "Test ban", expires_at: 1.day.ago)
    assert ban.expired?, "Ban with past expires_at should be expired"
  end

  test "should not be expired when active" do
    ban = Ban.create!(ip_address: "192.168.1.100", reason: "Test ban", expires_at: 1.day.from_now)
    assert_not ban.expired?, "Active ban should not be expired"
  end

  # Scope tests
  test "active scope should return unexpired bans" do
    active_ban = Ban.create!(ip_address: "192.168.1.100", reason: "Active", expires_at: 1.day.from_now)
    permanent_ban = Ban.create!(ip_address: "192.168.1.101", reason: "Permanent", expires_at: nil)
    expired_ban = Ban.create!(ip_address: "192.168.1.102", reason: "Expired", expires_at: 1.day.ago)

    active_bans = Ban.active
    assert_includes active_bans, active_ban
    assert_includes active_bans, permanent_ban
    assert_not_includes active_bans, expired_ban
  end

  test "by_ip scope should return bans matching IP" do
    ban1 = Ban.create!(ip_address: "192.168.1.100", reason: "Test 1")
    ban2 = Ban.create!(ip_address: "192.168.1.101", reason: "Test 2")

    bans = Ban.by_ip("192.168.1.100")
    assert_includes bans, ban1
    assert_not_includes bans, ban2
  end

  # Association test
  test "should belong to user (optional)" do
    assert_respond_to Ban.new, :user
  end

  # Cascade delete test
  test "should be destroyed when user is destroyed" do
    user = User.create!(email_address: "test@example.com", name: "Test User", password: "password123")
    ban = user.bans.create!(reason: "Test ban")

    assert_difference "Ban.count", -1 do
      user.destroy
    end
  end
end
