# frozen_string_literal: true

require "test_helper"

class ResourcesShowViewTest < ActionDispatch::IntegrationTest
  test "should render breadcrumb navigation on resource detail page" do
    entry = Entry.create!(
      title: "Ruby Testing Guide",
      url: "https://testing.example.com",
      published: true,
      status: :approved
    )
    entry.description = "A comprehensive guide to testing in Ruby"
    entry.save!

    get "/resources/#{entry.slug}"

    assert_response :success
    # Breadcrumb navigation should be present
    assert_select "nav[aria-label='Breadcrumb']"
    assert_select "nav a", text: "Home"
    assert_select "nav a", text: "Resources"
    assert_select "nav span.font-semibold", text: "Ruby Testing Guide"
  end

  test "should include SEO meta tags with entry data" do
    entry = Entry.create!(
      title: "Rails Performance Guide",
      url: "https://performance.example.com",
      published: true,
      status: :approved
    )
    entry.description = "Learn how to optimize your Rails application for better performance and scalability"
    entry.save!

    get "/resources/#{entry.slug}"

    assert_response :success

    # Page title
    assert_select "title", "Rails Performance Guide | ChooseRuby Resources"

    # Meta description
    assert_select "meta[name='description']"

    # Open Graph tags
    assert_select "meta[property='og:title'][content='Rails Performance Guide']"
    assert_select "meta[property='og:description']"
    assert_select "meta[property='og:type'][content='article']"
    assert_select "meta[property='og:url']"
    assert_select "meta[property='og:site_name'][content='ChooseRuby']"

    # Twitter Card tags
    assert_select "meta[name='twitter:card'][content='summary_large_image']"
    assert_select "meta[name='twitter:title'][content='Rails Performance Guide']"
    assert_select "meta[name='twitter:description']"
  end

  test "should include og:image and twitter:image when entry has image_url" do
    entry = Entry.create!(
      title: "Ruby Design Patterns",
      url: "https://patterns.example.com",
      image_url: "https://example.com/image.jpg",
      published: true,
      status: :approved
    )
    entry.description = "Common design patterns in Ruby"
    entry.save!

    get "/resources/#{entry.slug}"

    assert_response :success
    assert_select "meta[property='og:image'][content='https://example.com/image.jpg']"
    assert_select "meta[name='twitter:image'][content='https://example.com/image.jpg']"
  end
end
