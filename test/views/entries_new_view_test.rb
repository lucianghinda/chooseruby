# frozen_string_literal: true

require "test_helper"

class EntriesNewViewTest < ActionDispatch::IntegrationTest
  test "form renders all common fields" do
    get new_entry_path

    assert_response :success

    # Common fields
    assert_select "input[name='entry[title]']"
    assert_select "input[name='entry[url]']"
    assert_select "textarea[name='entry[description]']"
    assert_select "select[name='entry[resource_type]']"
    assert_select "input[name='entry[image_url]']"
    assert_select "select[name='entry[experience_level]']"
    assert_select "input[name='entry[submitter_name]']"
    assert_select "input[name='entry[submitter_email]']"
  end

  test "form includes hidden type-specific field sections for all 8 types" do
    get new_entry_path

    assert_response :success

    # Check for data attributes that identify each type section
    assert_select "[data-entry-type='RubyGem']"
    assert_select "[data-entry-type='Book']"
    assert_select "[data-entry-type='Course']"
    assert_select "[data-entry-type='Tutorial']"
    assert_select "[data-entry-type='Article']"
    assert_select "[data-entry-type='Tool']"
    assert_select "[data-entry-type='Podcast']"
    assert_select "[data-entry-type='Community']"
  end

  test "form includes category checkboxes" do
    get new_entry_path

    assert_response :success

    # Check for category checkboxes
    assert_select "input[type='checkbox'][name='entry[category_ids][]']", minimum: 1
  end

  test "form displays error messages when validation fails" do
    # Submit form with invalid data but valid resource_type to avoid ArgumentError
    post entries_path, params: {
      entry: {
        title: "",
        url: "",
        submitter_email: "",
        resource_type: "RubyGem"
      }
    }

    assert_response :unprocessable_entity

    # Check for error summary section
    assert_select ".border-rose-200.bg-rose-50", minimum: 1
  end

  test "form resource type dropdown includes all 8 delegated types" do
    get new_entry_path

    assert_response :success

    # Check dropdown has all 8 resource types
    assert_select "select[name='entry[resource_type]'] option[value='RubyGem']"
    assert_select "select[name='entry[resource_type]'] option[value='Book']"
    assert_select "select[name='entry[resource_type]'] option[value='Course']"
    assert_select "select[name='entry[resource_type]'] option[value='Tutorial']"
    assert_select "select[name='entry[resource_type]'] option[value='Article']"
    assert_select "select[name='entry[resource_type]'] option[value='Tool']"
    assert_select "select[name='entry[resource_type]'] option[value='Podcast']"
    assert_select "select[name='entry[resource_type]'] option[value='Community']"
  end

  test "form follows existing styling patterns with rounded-3xl and rose accents" do
    get new_entry_path

    assert_response :success

    # Check for rose accent colors and rounded styling
    assert_select ".rounded-3xl", minimum: 1
    assert_select ".bg-rose-500, .bg-rose-400", minimum: 1
  end

  test "RubyGem type-specific fields are present" do
    get new_entry_path

    assert_response :success

    # RubyGem specific fields
    assert_select "[data-entry-type='RubyGem'] input[name='entry[gem_name]']"
    assert_select "[data-entry-type='RubyGem'] input[name='entry[github_url]']"
    assert_select "[data-entry-type='RubyGem'] input[name='entry[documentation_url]']"
  end

  test "Community type-specific fields are present" do
    get new_entry_path

    assert_response :success

    # Community specific fields
    assert_select "[data-entry-type='Community'] input[name='entry[platform]']"
    assert_select "[data-entry-type='Community'] input[name='entry[join_url]']"
  end
end
