# frozen_string_literal: true

require "test_helper"

class AuthorsHelperTest < ActionView::TestCase
  tests AuthorsHelper

  ALL_URLS = {
    github_url: "https://github.com/matz",
    gitlab_url: "https://gitlab.com/matz",
    twitter_url: "https://x.com/matz",
    bluesky_url: "https://bsky.app/profile/matz",
    linkedin_url: "https://linkedin.com/in/matz",
    website_url: "https://matz.example.com",
    blog_url: "https://blog.example.com/matz",
    youtube_url: "https://youtube.com/@matz",
    twitch_url: "https://twitch.tv/matz",
    ruby_social_url: "https://ruby.social/@matz"
  }.freeze

  test "author_social_links returns no links when the author has no urls" do
    author = Author.new(name: "No Links")

    assert_empty author_social_links(author)
  end

  test "author_social_links returns every platform in display order" do
    author = Author.new(name: "All Links", **ALL_URLS)

    assert_equal [
      "GitHub",
      "GitLab",
      "X (Twitter)",
      "Bluesky",
      "LinkedIn",
      "Website",
      "Blog",
      "YouTube",
      "Twitch",
      "Ruby.social"
    ], author_social_links(author).map { |link| link[:name] }
  end

  test "author_social_links carries the author url of each platform" do
    author = Author.new(name: "All Links", **ALL_URLS)

    assert_equal ALL_URLS.values, author_social_links(author).map { |link| link[:url] }
  end

  test "author_social_links gives every link a non-empty icon path" do
    author = Author.new(name: "All Links", **ALL_URLS)

    author_social_links(author).each do |link|
      assert_predicate link[:icon_path], :present?, "#{link[:name]} is missing an icon path"
    end
  end

  test "author_social_links only includes the platforms the author filled in" do
    author = Author.new(name: "Partial", github_url: "https://github.com/matz", website_url: "https://matz.example.com")

    links = author_social_links(author)

    assert_equal [ "GitHub", "Website" ], links.map { |link| link[:name] }
    assert_equal [ "https://github.com/matz", "https://matz.example.com" ], links.map { |link| link[:url] }
  end

  test "author_social_links skips urls that are blank rather than nil" do
    author = Author.new(name: "Blank Links", **ALL_URLS.transform_values { "" })

    assert_empty author_social_links(author)
  end
end
