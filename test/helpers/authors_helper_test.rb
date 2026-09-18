# frozen_string_literal: true

require "test_helper"

class AuthorsHelperTest < ActionView::TestCase
  SOCIAL_URLS = {
    github_url: "https://github.com/matz",
    gitlab_url: "https://gitlab.com/matz",
    twitter_url: "https://twitter.com/matz",
    bluesky_url: "https://bsky.app/profile/matz",
    linkedin_url: "https://linkedin.com/in/matz",
    website_url: "https://matz.example.com",
    blog_url: "https://blog.matz.example.com",
    youtube_url: "https://youtube.com/@matz",
    twitch_url: "https://twitch.tv/matz",
    ruby_social_url: "https://ruby.social/@matz"
  }.freeze

  test "author_social_links returns one link per present URL in display order" do
    author = Author.new(name: "Matz", **SOCIAL_URLS)

    links = author_social_links(author)

    assert_equal SOCIAL_URLS.values, links.map { |link| link[:url] }
    assert_equal %w[GitHub GitLab X\ (Twitter) Bluesky LinkedIn Website Blog YouTube Twitch Ruby.social], links.map { |link| link[:name] }
    assert links.all? { |link| link[:icon_path].start_with?("M") }
  end

  test "author_social_links skips blank URLs" do
    author = Author.new(name: "Matz", github_url: "https://github.com/matz")

    links = author_social_links(author)

    assert_equal [ "https://github.com/matz" ], links.map { |link| link[:url] }
  end

  test "author_social_links is empty for an author without URLs" do
    assert_empty author_social_links(Author.new(name: "Matz"))
  end
end
