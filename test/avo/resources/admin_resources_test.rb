# frozen_string_literal: true

require "test_helper"
require "ostruct"
require_relative "../avo_admin_helper"

# Drives the Avo admin pages of the supporting resources: Category, the
# CategoriesEntry join, EntryReview and User.
class AvoAdminResourcesTest < ActionDispatch::IntegrationTest
  include AvoAdminHelper

  setup do
    sign_in_as_admin
    @entry = Entry.create!(
      title: "Entry For Admin Resources",
      description: "Used by the supporting admin resources",
      url: "https://example.com/entry-for-admin-resources",
      entryable: RubyGem.create!(gem_name: "entry-for-admin-resources"),
      status: :approved,
      published: true
    )
  end

  # --- Category ------------------------------------------------------------

  test "category index lists the categories with their display order" do
    body = get_avo("/avo/resources/categories")

    assert_match categories(:testing).name, body
    assert_match "Display order", body
    assert_match "Entries count", body
  end

  test "category index hides the timestamps" do
    body = get_avo("/avo/resources/categories")

    assert_no_match(/Created at/, body)
    assert_no_match(/Updated at/, body)
  end

  test "category show renders the description, icon and slug" do
    category = Category.create!(
      name: "Avo Test Category",
      slug: "avo-test-category",
      description: "Described for the admin panel",
      icon: "beaker",
      display_order: 9
    )

    body = get_avo("/avo/resources/categories/#{category.id}")

    assert_match "Described for the admin panel", body
    assert_match "beaker", body
    assert_match "avo-test-category", body
  end

  test "category show lists the entries in the category" do
    category = Category.create!(name: "Populated Avo Category", slug: "populated-avo-category")
    category.entries << @entry

    body = get_avo("/avo/resources/categories/#{category.id}")
    assert_match "has_many_field_show_entries", body

    frame = get_avo("/avo/resources/categories/#{category.id}/entries" \
                    "?view=show&turbo_frame=has_many_field_show_entries")
    assert_match @entry.title, frame
  end

  test "category new renders the form" do
    body = get_avo("/avo/resources/categories/new")

    assert_match "Name", body
    assert_match "Max 500 characters", body
    assert_match "Lower numbers appear first", body
  end

  test "category edit keeps the slug read only" do
    body = get_avo("/avo/resources/categories/#{categories(:testing).id}/edit")

    assert_match "Auto-generated from name", body
    assert_match(/data-field-id="slug".*?disabled="disabled"/m, body)
  end

  test "category search narrows categories by name" do
    context = OpenStruct.new(params: { q: categories(:testing).name }, query: Category.all)
    results = context.instance_exec(&Avo::Resources::Category.search[:query])

    assert_includes results, categories(:testing)
    assert_not_includes results, categories(:authentication)
  end

  # --- CategoriesEntry -----------------------------------------------------

  test "categories entry index lists the join rows with their flags" do
    CategoriesEntry.create!(entry: @entry, category: categories(:testing), is_primary: true, is_featured: true)

    body = get_avo("/avo/resources/categories_entries")

    assert_match "Is primary", body
    assert_match "Is featured", body
    assert_match "Category", body
    assert_match "Entry", body
  end

  test "categories entry show links both sides of the join" do
    join = CategoriesEntry.create!(entry: @entry, category: categories(:testing), is_primary: true)

    body = get_avo("/avo/resources/categories_entries/#{join.id}")

    assert_match "/avo/resources/categories/#{categories(:testing).id}", body
    assert_match "/avo/resources/entries/#{@entry.id}", body
  end

  test "categories entry new renders the form" do
    body = get_avo("/avo/resources/categories_entries/new")

    assert_match "Category", body
    assert_match "Entry", body
    assert_match "Only one primary category per entry", body
    assert_match "Mark this entry as featured in this category", body
  end

  test "categories entry edit renders the join prefilled" do
    join = CategoriesEntry.create!(entry: @entry, category: categories(:testing))

    body = get_avo("/avo/resources/categories_entries/#{join.id}/edit")

    assert_match categories(:testing).name, body
  end

  # --- EntryReview ---------------------------------------------------------

  test "entry review index lists the reviews with their decision" do
    EntryReview.create!(entry: @entry, status: :approved, comment: "Looks good to publish")

    body = get_avo("/avo/resources/entry_reviews")

    assert_match "Status", body
    assert_match "Entry", body
    assert_match "Created at", body
    assert_no_match(/Looks good to publish/, body,
                    "the comment textarea is not part of the index table")
  end

  test "entry review index hides the reviewer id" do
    EntryReview.create!(entry: @entry, status: :approved)

    body = get_avo("/avo/resources/entry_reviews")

    assert_no_match(/Reviewer/, body)
  end

  test "entry review show renders the comment and links the reviewed entry" do
    review = EntryReview.create!(entry: @entry, status: :rejected, comment: "Needs a better description", reviewer_id: 7)

    body = get_avo("/avo/resources/entry_reviews/#{review.id}")

    assert_match "Needs a better description", body
    assert_match "/avo/resources/entries/#{@entry.id}", body
    assert_match(/data-field-id="reviewer_id".*?>\s*7\s*</m, body)
  end

  test "entry review new offers both review decisions" do
    body = get_avo("/avo/resources/entry_reviews/new")

    assert_match "<option selected=\"selected\" value=\"approved\"", body
    assert_match "<option value=\"rejected\"", body
    assert_match "Feedback for the submitter", body
  end

  test "entry review edit renders the review prefilled" do
    review = EntryReview.create!(entry: @entry, status: :approved, comment: "Prefilled comment")

    body = get_avo("/avo/resources/entry_reviews/#{review.id}/edit")

    assert_match "Prefilled comment", body
    assert_match "Admin reviewer id (future use)", body
  end

  # --- User ----------------------------------------------------------------
  #
  # The User resource has no Avo::UsersController, so /avo/resources/users
  # raises ActionDispatch::MissingController and the pages cannot be driven.
  # Its field declarations are asserted directly instead. See the test report.

  test "user resource declares the account fields" do
    fields = user_resource_fields(:show)

    assert_equal %i[id email_address name role status sessions created_at updated_at], fields.map(&:id)
  end

  test "user resource exposes the password only on the new and edit forms" do
    assert_not_includes user_resource_fields(:show).map(&:id), :password
    assert_not_includes user_resource_fields(:index).map(&:id), :password

    password_field = user_resource_fields(:edit).find { |field| field.id == :password }
    assert_not_nil password_field, "admins must be able to set a password when editing a user"
    assert_equal "Leave blank to keep current password", password_field.help
  end

  test "user resource offers every role and status of the model" do
    fields = user_resource_fields(:edit).index_by(&:id)

    assert_equal ::User.roles.keys, fields[:role].options_for_select.keys
    assert_equal ::User.statuses.keys, fields[:status].options_for_select.keys
  end

  private

  def user_resource_fields(view)
    resource = Avo::Resources::User.new(record: users(:admin), view: view)
    resource.detect_fields
    resource.get_field_definitions.select { |field| field.visible_in_view?(view: Avo::ViewInquirer.new(view.to_s)) }
  end
end
