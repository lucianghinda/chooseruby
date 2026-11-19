# frozen_string_literal: true

require "test_helper"
require_relative "../avo_admin_helper"

# Every other Avo resource has a controller under app/controllers/avo/; the
# User one was missing, so these pages raised MissingController.
class AvoUserResourcePagesTest < ActionDispatch::IntegrationTest
  include AvoAdminHelper

  setup { sign_in_as_admin }

  test "the users index lists the signed in admin" do
    body = get_avo "/avo/resources/users"

    assert_includes body, users(:admin).email_address
  end

  test "the users show page renders" do
    body = get_avo "/avo/resources/users/#{users(:admin).id}"

    assert_includes body, users(:admin).email_address
  end

  test "the new user page renders" do
    get_avo "/avo/resources/users/new"
  end

  test "the edit user page renders" do
    get_avo "/avo/resources/users/#{users(:admin).id}/edit"
  end
end
