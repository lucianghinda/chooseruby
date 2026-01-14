# frozen_string_literal: true

# This runs after Rails initialization but before requests are handled
Rails.application.config.after_initialize do
  # Include authentication concerns in Avo's base controller
  if defined?(Avo::BaseController)
    Avo::BaseController.class_eval do
      include SetCurrentRequest
      include BlockBannedRequests
      include Authentication
      include Authorization
    end
  end
end
