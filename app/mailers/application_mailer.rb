# frozen_string_literal: true

# Shared sender and layout for application notifications.
class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"
end
