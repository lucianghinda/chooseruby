# frozen_string_literal: true

require "test_helper"
require_relative "../avo_admin_helper"

# Drives the Avo admin pages of the 19 delegated entryable types.
#
# Every one of these resources is a `fields` DSL body that only runs while a
# page renders, so each type gets its index, show, new and edit view requested
# and the rendered output checked against a distinctive attribute value.
class AvoEntryableResourcesTest < ActionDispatch::IntegrationTest
  include AvoAdminHelper

  # route segment => [model, attributes, value expected on the rendered pages]
  TYPES = {
    "articles" => [ ::Article, { author_name: "Ada Articlewriter", platform: "Dev.to", reading_time_minutes: 7 }, "Ada Articlewriter" ],
    "blogs" => [ ::Blog, { name: "The Avo Test Blog" }, "The Avo Test Blog" ],
    "books" => [ ::Book, { publisher: "Avo Test Press", publication_year: 2021, page_count: 320, format: :ebook }, "Avo Test Press" ],
    "channels" => [ ::Channel, { name: "The Avo Test Channel" }, "The Avo Test Channel" ],
    "communities" => [ ::Community, { platform: "Discord", join_url: "https://discord.gg/avo-test", member_count: 42 }, "https://discord.gg/avo-test" ],
    "courses" => [ ::Course, { platform: "Avo Academy", instructor: "Cora Courseteacher", currency: "USD", price_cents: 9999 }, "Cora Courseteacher" ],
    "development_environments" => [ ::DevelopmentEnvironment, { name: "The Avo Test Editor" }, "The Avo Test Editor" ],
    "directories" => [ ::Directory, { name: "The Avo Test Directory" }, "The Avo Test Directory" ],
    "documentations" => [ ::Documentation, { name: "The Avo Test Docs" }, "The Avo Test Docs" ],
    "frameworks" => [ ::Framework, { name: "The Avo Test Framework" }, "The Avo Test Framework" ],
    "job_boards" => [ ::JobBoard, { name: "The Avo Test Job Board" }, "The Avo Test Job Board" ],
    "newsletters" => [ ::Newsletter, { name: "The Avo Test Newsletter" }, "The Avo Test Newsletter" ],
    "podcasts" => [ ::Podcast, { host: "Pat Podcasthost", episode_count: 120, frequency: "Weekly" }, "Pat Podcasthost" ],
    "products" => [ ::Product, { name: "The Avo Test Product" }, "The Avo Test Product" ],
    "ruby_gems" => [ ::RubyGem, { gem_name: "avo-test-gem", current_version: "1.2.3", downloads_count: 999 }, "avo-test-gem" ],
    "testing_resources" => [ ::TestingResource, { name: "The Avo Test Testing Resource" }, "The Avo Test Testing Resource" ],
    "tools" => [ ::Tool, { tool_type: "Linter", license: "MIT", is_open_source: true }, "Linter" ],
    "tutorials" => [ ::Tutorial, { author_name: "Tom Tutorialwriter", platform: "YouTube", reading_time_minutes: 15 }, "Tom Tutorialwriter" ],
    "videos" => [ ::Video, { name: "The Avo Test Video" }, "The Avo Test Video" ]
  }.freeze

  setup { sign_in_as_admin }

  TYPES.each do |route, (model, attributes, expected)|
    test "#{route} index lists the records with their attributes" do
      model.create!(attributes)

      body = get_avo("/avo/resources/#{route}")

      assert_match expected, body
    end

    test "#{route} show renders the record and links its entry" do
      record = model.create!(attributes)
      entry = Entry.create!(
        title: "Entry for #{route}",
        description: "Links the delegated type to an entry",
        url: "https://example.com/entry-for-#{route}",
        entryable: record,
        status: :approved
      )

      body = get_avo("/avo/resources/#{route}/#{record.id}")

      assert_match expected, body
      assert_match "has_one_field_show_entry", body

      frame = get_avo("/avo/resources/#{route}/#{record.id}/entry/#{entry.id}" \
                      "?view=show&turbo_frame=has_one_field_show_entry")
      assert_match entry.title, frame
    end

    test "#{route} new renders an empty form" do
      body = get_avo("/avo/resources/#{route}/new")

      attributes.each_key do |attribute|
        assert_match attribute.to_s.humanize, body, "the new form must offer #{attribute}"
      end
    end

    test "#{route} edit renders the record prefilled" do
      record = model.create!(attributes)

      body = get_avo("/avo/resources/#{route}/#{record.id}/edit")

      assert_match expected, body
    end
  end

  test "every delegated type resource points admins at the two step creation flow" do
    TYPES.each_key do |route|
      resource = "Avo::Resources::#{route.classify.camelize}".constantize
      assert_match(/then create an Entry/, resource.description,
                   "#{resource} must explain that an Entry has to be created afterwards")
    end
  end
end
