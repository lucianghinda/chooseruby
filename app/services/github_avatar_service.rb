# frozen_string_literal: true

# Turns a GitHub profile URL into its avatar URL, e.g.
#   GithubAvatarService.call("https://github.com/matz") # => "https://github.com/matz.png"
#   GithubAvatarService.call("not a url")                # => nil
module GithubAvatarService
  GITHUB_URL = %r{github\.com/([^/]+)/?\z}

  module_function

  def call(github_url)
    return nil if github_url.blank?

    username = github_url[GITHUB_URL, 1]
    return nil if username.blank?

    "https://github.com/#{username}.png"
  rescue => error
    Rails.logger.warn("GitHub avatar fetch failed for #{github_url}: #{error.message}")
    nil
  end
end
