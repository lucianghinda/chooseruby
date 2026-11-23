# frozen_string_literal: true

require "test_helper"

class BrowserSupportTest < ActionDispatch::IntegrationTest
  test "blocks Firefox versions below Tailwind CSS v4 support" do
    get root_path, headers: { "User-Agent" => firefox_user_agent(127) }

    assert_response :not_acceptable
  end

  test "allows Firefox 128" do
    get root_path, headers: { "User-Agent" => firefox_user_agent(128) }

    assert_response :success
  end

  test "keeps Rails modern browser policy for Chrome" do
    chrome_119 = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"
    chrome_120 = chrome_119.sub("119.0.0.0", "120.0.0.0")

    get root_path, headers: { "User-Agent" => chrome_119 }
    assert_response :not_acceptable

    get root_path, headers: { "User-Agent" => chrome_120 }
    assert_response :success
  end

  private

  def firefox_user_agent(version)
    "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:#{version}.0) Gecko/20100101 Firefox/#{version}.0"
  end
end
