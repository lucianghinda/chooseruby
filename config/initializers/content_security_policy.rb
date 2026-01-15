# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self

    policy.base_uri :self
    policy.form_action :self
    policy.frame_ancestors :none
    policy.object_src :none

    policy.font_src :self, :data
    policy.img_src  :self, :data, :https

    policy.script_src :self, "https://cdn.jsdelivr.net"
    policy.style_src  :self

    policy.connect_src :self

    policy.upgrade_insecure_requests
    policy.report_uri "/csp-violation-report"
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Report violations without enforcing the policy.
  # Once verified clean, remove this line to enforce.
  config.content_security_policy_report_only = true
end
