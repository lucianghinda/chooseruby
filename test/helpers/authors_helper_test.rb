# frozen_string_literal: true

require "test_helper"

class AuthorsHelperTest < ActionView::TestCase
  test "blank social links are omitted" do
    assert_empty author_social_links(Author.new)
  end

  test "social links preserve the configured names URLs and icons" do
    platforms = {
      github: "GitHub", gitlab: "GitLab", twitter: "X (Twitter)", bluesky: "Bluesky",
      linkedin: "LinkedIn", website: "Website", blog: "Blog", youtube: "YouTube",
      twitch: "Twitch", ruby_social: "Ruby.social"
    }
    attributes = platforms.to_h { |platform, _name| [ "#{platform}_url", "https://example.com/#{platform}" ] }
    links = author_social_links(Author.new(attributes))

    assert_equal platforms.values, links.pluck(:name)
    assert_equal attributes.values, links.pluck(:url)
    assert links.all? { |link| link.fetch(:icon_path).start_with?("M") }
  end
end
