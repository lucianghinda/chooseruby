# frozen_string_literal: true

# Shared helper for integration tests that drive the Avo admin panel.
#
# Avo resources are DSL class bodies: their `fields` blocks, `visible:` lambdas
# and computed-field blocks only run while a page is being rendered, so these
# tests sign in as an admin and request the real Avo controller actions.
module AvoAdminHelper
  def sign_in_as_admin
    post "/session", params: { email_address: users(:admin).email_address, password: "password" }
    assert_redirected_to "/avo/"
  end

  # Requests an Avo page and fails loudly with the response body when it is not
  # a successful render, so a broken resource is diagnosable from the failure.
  def get_avo(path)
    get path
    assert_response :success, "GET #{path} responded #{response.status}\n#{response.body.first(1500)}"
    response.body
  end

  # Submits an Avo form. Avo redirects to the record on success and re-renders
  # the form with 422 when a param was rejected, so anything but a redirect is
  # a failure and the body is shown to make it diagnosable.
  def submit_avo(method, path, params)
    public_send(method, path, params: params)
    assert_response :redirect, "#{method.upcase} #{path} responded #{response.status}\n#{response.body.first(1500)}"
  end
end
