# frozen_string_literal: true

require "test_helper"
require_relative "../avo_admin_helper"

# Creating and updating the single-attribute entryable types through the Avo admin.
#
# These eleven controllers used to override `model_params` with a hand written
# `permit`. Avo derives the permitted set from the resource's field definitions,
# so the overrides were removed; these tests prove the attribute still reaches
# the record on create and on update.
class AvoEntryableWritesTest < ActionDispatch::IntegrationTest
  include AvoAdminHelper

  # route segment => model
  TYPES = {
    "blogs" => ::Blog,
    "channels" => ::Channel,
    "development_environments" => ::DevelopmentEnvironment,
    "directories" => ::Directory,
    "documentations" => ::Documentation,
    "frameworks" => ::Framework,
    "job_boards" => ::JobBoard,
    "newsletters" => ::Newsletter,
    "products" => ::Product,
    "testing_resources" => ::TestingResource,
    "videos" => ::Video
  }.freeze

  setup { sign_in_as_admin }

  TYPES.each do |route, model|
    param_key = model.model_name.param_key

    test "#{route} create stores the submitted name" do
      assert_difference "#{model}.count", 1 do
        submit_avo(:post, "/avo/resources/#{route}", { param_key => { name: "Created via Avo #{route}" } })
      end

      assert_equal "Created via Avo #{route}", model.last.name
    end

    test "#{route} update stores the edited name" do
      record = model.create!(name: "Before the Avo edit")

      submit_avo(:patch, "/avo/resources/#{route}/#{record.id}", { param_key => { name: "After the Avo edit" } })

      assert_equal "After the Avo edit", record.reload.name
    end
  end
end
