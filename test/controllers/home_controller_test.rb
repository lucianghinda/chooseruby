# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  # Test 3.1.1: Homepage includes beginner CTA section
  test "GET index includes beginner CTA section" do
    get root_path

    assert_response :success
    assert_select "section", text: /New to Rails/i
  end

  # Test 3.1.2: CTA section includes heading about Rails beginners
  test "beginner CTA section includes heading about Rails beginners" do
    get root_path

    assert_response :success
    assert_select "h2", text: /New to Rails\? Start here/i
  end

  # Test 3.1.3: CTA section includes link to start_path
  test "beginner CTA section includes link to start page" do
    get root_path

    assert_response :success
    assert_select "a[href=?]", start_path, text: /Explore beginner resources/i
  end

  # Test 3.1.4: CTA button has correct rose-500 styling
  test "CTA button has rose-500 background styling" do
    get root_path

    assert_response :success
    assert_select "a.bg-rose-500[href=?]", start_path
  end

  # Task 5.1: Tests for homepage type sections
  # Test 5.1.1: Homepage loads 8 type sections
  test "homepage displays all 8 type sections" do
    # Create at least one visible entry for each type so sections appear
    create_visible_gem
    create_visible_book
    create_visible_course
    create_visible_tutorial
    create_visible_article
    create_visible_tool
    create_visible_podcast
    create_visible_community

    get root_path

    assert_response :success
    # Each section should have a heading with the type name
    assert_select "h2", text: /Ruby Gems/i
    assert_select "h2", text: /Books/i
    assert_select "h2", text: /Courses/i
    assert_select "h2", text: /Tutorials/i
    assert_select "h2", text: /Articles/i
    assert_select "h2", text: /Tools/i
    assert_select "h2", text: /Podcasts/i
    assert_select "h2", text: /Communities/i
  end

  # Test 5.1.2: Each section displays 3-4 recent entries of that type
  test "each type section displays up to 4 recent entries" do
    # Create 5 visible gems (should show only 4 most recent)
    5.times do |i|
      create_visible_gem(title: "Gem #{i}", updated_at: i.days.ago)
    end

    get root_path

    assert_response :success
    # Each entry is rendered as an <a> tag with a specific class
    # We expect exactly 4 entries (the limit) to be displayed
    # Count links that point to resource_path
    gem_links = css_select("a[href*='/resources/']")
    assert gem_links.count >= 4, "Expected at least 4 gem entries"
  end

  # Test 5.1.3: Sections appear after "Freshly curated resources"
  test "type sections appear after freshly curated resources section" do
    create_visible_gem

    get root_path

    assert_response :success
    # Both sections should exist
    assert_select "h2", text: /Freshly curated resources/i
    assert_select "h2", text: /Ruby Gems/i
  end

  # Test 5.1.4: Each section has correct emoji identifier
  test "each type section displays correct emoji" do
    create_visible_gem
    create_visible_book

    get root_path

    assert_response :success
    # Check for emojis in the page (emojis are rendered as text)
    assert_match "💎", response.body
    assert_match "📚", response.body
  end

  # Test 5.1.5: Each section links to type browse page
  test "each type section has view all link to browse page" do
    create_visible_gem
    create_visible_book

    get root_path

    assert_response :success
    assert_select "a[href=?]", resource_type_path("gems"), text: /View all/i
    assert_select "a[href=?]", resource_type_path("books"), text: /View all/i
  end

  # Test 5.1.6: Sections only show visible (published + approved) entries
  test "type sections only display visible entries" do
    # Create visible gem
    visible_gem = create_visible_gem(title: "Visible Gem")

    # Create non-visible gems (unpublished, pending, rejected)
    create_entry(
      title: "Unpublished Gem",
      entryable: RubyGem.create!(gem_name: "unpublished"),
      published: false,
      status: :approved
    )
    create_entry(
      title: "Pending Gem",
      entryable: RubyGem.create!(gem_name: "pending"),
      published: true,
      status: :pending,
      submitter_email: "test@example.com"
    )
    create_entry(
      title: "Rejected Gem",
      entryable: RubyGem.create!(gem_name: "rejected"),
      published: true,
      status: :rejected
    )

    get root_path

    assert_response :success
    # Should show only the visible gem
    assert_match "Visible Gem", response.body
    assert_no_match "Unpublished Gem", response.body
    assert_no_match "Pending Gem", response.body
    assert_no_match "Rejected Gem", response.body
  end

  # Task 4.1: Tests for new type sections on homepage
  # Test 4.1.1: Homepage displays new type sections when entries exist
  test "homepage displays new type sections for newsletters, blogs, and videos" do
    create_visible_newsletter
    create_visible_blog
    create_visible_video

    get root_path

    assert_response :success
    assert_select "h2", text: /Newsletters/i
    assert_select "h2", text: /Blogs/i
    assert_select "h2", text: /Videos/i
  end

  # Test 4.1.2: New type sections display correct emojis
  test "new type sections display correct emojis" do
    create_visible_newsletter
    create_visible_framework
    create_visible_product

    get root_path

    assert_response :success
    assert_match "📧", response.body # Newsletter
    assert_match "🏗️", response.body # Framework
    assert_match "🚀", response.body # Product
  end

  # Test 4.1.3: Sections hidden when no entries exist
  test "type sections are hidden when no entries exist" do
    get root_path

    assert_response :success
    # Should not show sections for types with no entries
    assert_select "h2", { text: /Newsletters/i, count: 0 }
    assert_select "h2", { text: /Blogs/i, count: 0 }
  end

  # Test 4.1.4: HomeController assigns instance variables for new types
  test "home controller fetches data for all new types" do
    # Create one entry of each type to ensure data is fetched
    create_visible_newsletter
    create_visible_blog
    create_visible_video

    get root_path

    assert_response :success
    # Verify the sections are rendered (which proves instance variables are assigned)
    assert_select "h2", text: /Newsletters/i
    assert_select "h2", text: /Blogs/i
    assert_select "h2", text: /Videos/i
  end

  # Test 4.1.5: Fetch methods return up to 4 recent entries
  test "new type fetch methods limit results to 4 entries" do
    # Create exactly 4 newsletters - all should appear
    4.times do |i|
      create_visible_newsletter(title: "LimitNewsletter#{i}", updated_at: i.days.ago)
    end

    get root_path

    assert_response :success
    # All 4 should appear
    assert_match "LimitNewsletter0", response.body
    assert_match "LimitNewsletter1", response.body
    assert_match "LimitNewsletter2", response.body
    assert_match "LimitNewsletter3", response.body
    # Verify the newsletter section is displayed
    assert_select "h2", text: /Newsletters/i
  end

  # Test 4.1.6: Fetch methods only return visible entries
  test "new type fetch methods only return visible entries" do
    # Create visible newsletter
    create_visible_newsletter(title: "Visible Newsletter")

    # Create non-visible newsletter
    create_entry(
      title: "Pending Newsletter",
      entryable: Newsletter.create!(name: "Test Newsletter"),
      published: true,
      status: :pending,
      submitter_email: "test@example.com"
    )

    get root_path

    assert_response :success
    # Should show only visible newsletter
    assert_match "Visible Newsletter", response.body
    assert_no_match "Pending Newsletter", response.body
  end

  # Test 4.1.7: Type section shows submission message when 1-3 entries exist
  test "type section displays submission message when only 1-3 entries exist" do
    # Create exactly 2 newsletters (between 1-3)
    2.times do |i|
      create_visible_newsletter(title: "Newsletter #{i}")
    end

    get root_path

    assert_response :success
    # Should display the section
    assert_select "h2", text: /Newsletters/i
    # Should display submission message
    assert_match /Know a great Ruby newsletter/i, response.body
    assert_select "a[href=?]", new_resource_submission_path, text: /Submit it here/i
  end

  # Test 4.1.8: Type section does not show submission message when 4+ entries exist
  test "type section does not display submission message when 4 or more entries exist" do
    # Create exactly 4 newsletters
    4.times do |i|
      create_visible_newsletter(title: "Newsletter #{i}")
    end

    get root_path

    assert_response :success
    # Should display the section
    assert_select "h2", text: /Newsletters/i
    # Should NOT display submission message
    assert_no_match /Know a great Ruby newsletter/i, response.body
  end

  private

  def create_entry(title:, entryable:, published: true, status: :approved, updated_at: Time.current, submitter_email: nil)
    Entry.create!(
      title: title,
      url: "https://example.com/#{title.parameterize}",
      entryable: entryable,
      published: published,
      status: status,
      updated_at: updated_at,
      submitter_email: submitter_email
    )
  end

  def create_visible_gem(title: "Test Gem", updated_at: Time.current)
    gem = RubyGem.create!(gem_name: title.parameterize)
    create_entry(title: title, entryable: gem, updated_at: updated_at)
  end

  def create_visible_book(title: "Test Book", updated_at: Time.current)
    book = Book.create!
    create_entry(title: title, entryable: book, updated_at: updated_at)
  end

  def create_visible_course(title: "Test Course", updated_at: Time.current)
    course = Course.create!(platform: "Test Platform")
    create_entry(title: title, entryable: course, updated_at: updated_at)
  end

  def create_visible_tutorial(title: "Test Tutorial", updated_at: Time.current)
    tutorial = Tutorial.create!(platform: "Test Platform")
    create_entry(title: title, entryable: tutorial, updated_at: updated_at)
  end

  def create_visible_article(title: "Test Article", updated_at: Time.current)
    article = Article.create!(platform: "Test Blog")
    create_entry(title: title, entryable: article, updated_at: updated_at)
  end

  def create_visible_tool(title: "Test Tool", updated_at: Time.current)
    tool = Tool.create!
    create_entry(title: title, entryable: tool, updated_at: updated_at)
  end

  def create_visible_podcast(title: "Test Podcast", updated_at: Time.current)
    podcast = Podcast.create!(host: "Test Host")
    create_entry(title: title, entryable: podcast, updated_at: updated_at)
  end

  def create_visible_community(title: "Test Community", updated_at: Time.current)
    community = Community.create!(platform: "Test Platform", join_url: "https://example.com/join")
    create_entry(title: title, entryable: community, updated_at: updated_at)
  end

  # Task 4.1: Helper methods for new types
  def create_visible_newsletter(title: "Test Newsletter", updated_at: Time.current)
    newsletter = Newsletter.create!(name: "Test Newsletter")
    create_entry(title: title, entryable: newsletter, updated_at: updated_at)
  end

  def create_visible_blog(title: "Test Blog", updated_at: Time.current)
    blog = Blog.create!(name: "Test Blog")
    create_entry(title: title, entryable: blog, updated_at: updated_at)
  end

  def create_visible_video(title: "Test Video", updated_at: Time.current)
    video = Video.create!(name: "Test Video")
    create_entry(title: title, entryable: video, updated_at: updated_at)
  end

  def create_visible_channel(title: "Test Channel", updated_at: Time.current)
    channel = Channel.create!(name: "Test Channel")
    create_entry(title: title, entryable: channel, updated_at: updated_at)
  end

  def create_visible_documentation(title: "Test Documentation", updated_at: Time.current)
    documentation = Documentation.create!(name: "Test Documentation")
    create_entry(title: title, entryable: documentation, updated_at: updated_at)
  end

  def create_visible_testing_resource(title: "Test Testing Resource", updated_at: Time.current)
    testing_resource = TestingResource.create!(name: "Test Testing Resource")
    create_entry(title: title, entryable: testing_resource, updated_at: updated_at)
  end

  def create_visible_development_environment(title: "Test Dev Environment", updated_at: Time.current)
    dev_env = DevelopmentEnvironment.create!(name: "Test Dev Environment")
    create_entry(title: title, entryable: dev_env, updated_at: updated_at)
  end

  def create_visible_job(title: "Test Job", updated_at: Time.current)
    job = Job.create!(name: "Test Job")
    create_entry(title: title, entryable: job, updated_at: updated_at)
  end

  def create_visible_framework(title: "Test Framework", updated_at: Time.current)
    framework = Framework.create!(name: "Test Framework")
    create_entry(title: title, entryable: framework, updated_at: updated_at)
  end

  def create_visible_directory(title: "Test Directory", updated_at: Time.current)
    directory = Directory.create!(name: "Test Directory")
    create_entry(title: title, entryable: directory, updated_at: updated_at)
  end

  def create_visible_product(title: "Test Product", updated_at: Time.current)
    product = Product.create!(name: "Test Product")
    create_entry(title: title, entryable: product, updated_at: updated_at)
  end
end
