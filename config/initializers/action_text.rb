# frozen_string_literal: true

# Remove inline style attributes from ActionText content to comply with CSP.
# This prevents CSP violations for style-src-attr when rendering rich text.
Rails.application.config.after_initialize do
  if ActionText::ContentHelper.respond_to?(:allowed_attributes=)
    current = ActionText::ContentHelper.allowed_attributes || Rails::HTML5::SafeListSanitizer.allowed_attributes
    ActionText::ContentHelper.allowed_attributes = current - %w[style]
  end
end
