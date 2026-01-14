# frozen_string_literal: true

require "test_helper"

class GithubAvatarServiceTest < ActiveSupport::TestCase
  test "extracts username from standard GitHub URL" do
    url = "https://github.com/matz"
    avatar_url = GithubAvatarService.call(url)

    assert_equal "https://github.com/matz.png", avatar_url
  end

  test "extracts username from GitHub URL with trailing slash" do
    url = "https://github.com/matz/"
    avatar_url = GithubAvatarService.call(url)

    assert_equal "https://github.com/matz.png", avatar_url
  end

  test "handles http GitHub URLs" do
    url = "http://github.com/matz"
    avatar_url = GithubAvatarService.call(url)

    assert_equal "https://github.com/matz.png", avatar_url
  end

  test "returns nil for blank URL" do
    avatar_url = GithubAvatarService.call("")

    assert_nil avatar_url
  end

  test "returns nil for nil URL" do
    avatar_url = GithubAvatarService.call(nil)

    assert_nil avatar_url
  end

  test "returns nil for invalid GitHub URL" do
    url = "https://example.com/notgithub"
    avatar_url = GithubAvatarService.call(url)

    assert_nil avatar_url
  end

  test "returns nil for GitHub URL without username" do
    url = "https://github.com/"
    avatar_url = GithubAvatarService.call(url)

    assert_nil avatar_url
  end

  test "integration: author fetches avatar on creation with github_url" do
    author = Author.create(
      name: "Yukihiro Matsumoto",
      github_url: "https://github.com/matz"
    )

    assert_equal "https://github.com/matz.png", author.reload.avatar_url
  end

  test "integration: author updates avatar when github_url changes" do
    author = Author.create(name: "Test Author")
    assert_nil author.avatar_url

    author.update(github_url: "https://github.com/dhh")

    assert_equal "https://github.com/dhh.png", author.reload.avatar_url
  end
end
