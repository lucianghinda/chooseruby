# frozen_string_literal: true

class ResourceSubmissionMailer < ApplicationMailer
  default to: -> { ENV.fetch("RESOURCE_SUBMISSION_RECIPIENT", "hello@chooseruby.com") }
  default from: -> { ENV.fetch("RESOURCE_SUBMISSION_SENDER", "hello@chooseruby.com") }

  def notify_team(submission)
    @submission = submission

    # Handle both Entry and ResourceSubmission models
    @categories = if submission.respond_to?(:selected_categories)
                    submission.selected_categories
    else
                    submission.categories
    end

    mail(subject: "New resource submission: #{submission.title}")
  end

  def confirm_submitter(submission)
    @submission = submission

    # Get email from submitter_email (Entry) or contact_email (ResourceSubmission)
    email = submission.try(:submitter_email) || submission.try(:contact_email)

    mail(
      to: email,
      subject: "We received your resource submission for ChooseRuby"
    )
  end

  def approval_notification(entry)
    @entry = entry

    mail(
      to: entry.submitter_email,
      subject: "Your ChooseRuby submission has been approved: #{entry.title}"
    )
  end

  def rejection_notification(entry)
    @entry = entry
    @comment = entry.entry_reviews.where(status: :rejected).last&.comment

    mail(
      to: entry.submitter_email,
      subject: "Update on your ChooseRuby submission: #{entry.title}"
    )
  end
end
