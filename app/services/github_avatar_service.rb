# frozen_string_literal: true

# Service class for fetching GitHub avatar URLs
#
# This service extracts a GitHub username from a GitHub URL and constructs
# the avatar URL using GitHub's public avatar endpoint.
#
# Usage:
#   avatar_url = GithubAvatarService.call("https://github.com/matz")
#   # Returns: "https://github.com/matz.png"
#
#   avatar_url = GithubAvatarService.call("invalid-url")
#   # Returns: nil
#
# GitHub Avatar URL Pattern:
#   https://github.com/{username}.png
#
# Supported URL formats:
#   - https://github.com/username
#   - https://github.com/username/
#   - http://github.com/username (will use https)
#
class GithubAvatarService
  # Extracts username from GitHub URL and returns avatar URL
  #
  # @param github_url [String] The GitHub profile URL
  # @return [String, nil] The avatar URL or nil on failure
  def self.call(github_url)
    new(github_url).call
  end

  def initialize(github_url)
    @github_url = github_url
  end

  def call
    return nil if @github_url.blank?

    username = extract_username
    return nil if username.blank?

    construct_avatar_url(username)
  rescue => e
    Rails.logger.warn("GitHub avatar fetch failed for #{@github_url}: #{e.message}")
    nil
  end

  private

  # Extract username from various GitHub URL formats
  def extract_username
    # Match patterns like:
    # https://github.com/username
    # https://github.com/username/
    # http://github.com/username
    match = @github_url.match(%r{github\.com/([^/]+)/?$})
    match[1] if match
  end

  # Construct the GitHub avatar URL
  def construct_avatar_url(username)
    "https://github.com/#{username}.png"
  end
end
