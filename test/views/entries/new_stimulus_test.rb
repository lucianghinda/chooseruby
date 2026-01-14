# frozen_string_literal: true

require "test_helper"

# Tests for Stimulus controller behavior on the entry submission form
# These tests verify that the necessary data attributes and structure are in place
# for Stimulus controllers to function correctly
class EntriesNewStimulusTest < ActionDispatch::IntegrationTest
  test "resource type select has entry-form controller data attributes" do
    get new_entry_path

    assert_response :success

    # Verify the resource type select has the correct Stimulus targets and actions
    assert_select 'select[data-entry-form-target="typeSelect"]'
    assert_select 'select[data-action*="change->entry-form#showFieldsForType"]'
  end

  test "type-specific field sections have correct data attributes for RubyGem" do
    get new_entry_path

    assert_response :success

    # Verify RubyGem section has the correct data attributes
    assert_select 'div[data-entry-type="RubyGem"][data-entry-form-target="typeFields"]' do
      assert_select 'input[name*="gem_name"]'
      assert_select 'input[name*="github_url"]'
    end
  end

  test "type-specific field sections have correct data attributes for Book" do
    get new_entry_path

    assert_response :success

    # Verify Book section has the correct data attributes
    assert_select 'div[data-entry-type="Book"][data-entry-form-target="typeFields"]' do
      assert_select 'input[name*="isbn"]'
      assert_select 'input[name*="publisher"]'
    end
  end

  test "category checkboxes have category-limit controller data attributes" do
    get new_entry_path

    assert_response :success

    # Verify category checkboxes have the correct Stimulus targets and actions
    assert_select 'div[data-controller="category-limit"]'
    assert_select 'input[type="checkbox"][data-category-limit-target="checkbox"]'
    assert_select 'input[type="checkbox"][data-action*="change->category-limit#checkLimit"]'
  end

  test "form has hashcash controller data attributes" do
    get new_entry_path

    assert_response :success

    # Verify form has hashcash controller
    assert_select 'form[data-controller*="hashcash"]'
    assert_select 'form[data-action*="submit->hashcash#generateToken"]'
  end

  test "hashcash token hidden field exists" do
    get new_entry_path

    assert_response :success

    # Verify hidden field for hashcash token
    assert_select 'input[type="hidden"][name="hashcash_token"][data-hashcash-target="token"]'
  end

  test "author search interface has correct data attributes" do
    get new_entry_path

    assert_response :success

    # Verify author search has the correct Stimulus controller and targets
    assert_select 'div[data-controller="author-search"]'
    assert_select 'input[data-author-search-target="input"]'
    assert_select 'div[data-author-search-target="results"]'
    assert_select 'input[type="hidden"][data-author-search-target="authorId"]'
  end

  test "all eight delegated type sections are present in HTML" do
    get new_entry_path

    assert_response :success

    # Verify all 8 type-specific field sections exist (for progressive enhancement)
    %w[RubyGem Book Course Tutorial Article Tool Podcast Community].each do |type|
      assert_select "div[data-entry-type='#{type}']", 1, "Expected to find section for #{type}"
    end
  end
end
