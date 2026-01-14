# frozen_string_literal: true

# Mailer for sending notifications about author proposal status changes
#
# This mailer handles:
# - Submission confirmation when proposal is first created
# - Approval notification when admin approves proposal
# - Rejection notification when admin rejects proposal with feedback
#
# All emails are sent to the proposal submitter's email address.
class AuthorProposalMailer < ApplicationMailer
  default from: -> { ENV.fetch("RESOURCE_SUBMISSION_SENDER", "hello@chooseruby.com") }

  # Sends confirmation email immediately after proposal submission
  #
  # Includes:
  # - Proposal ID for reference
  # - Expected review timeline
  # - What to expect next
  #
  # @param author_proposal [AuthorProposal] the submitted proposal
  # @return [Mail::Message] the email to be delivered
  def submission_confirmation(author_proposal)
    @proposal = author_proposal
    # Eager load author to avoid strict loading violation
    @author = author_proposal.author_id.present? ? Author.find(author_proposal.author_id) : nil

    mail(
      to: @proposal.submitter_email,
      subject: "Author Proposal Received - ID ##{@proposal.id}"
    )
  end

  # Sends approval notification when admin approves the proposal
  #
  # Includes:
  # - Link to the author profile
  # - Thank you message for contribution
  # - Invitation to submit more proposals
  #
  # @param author_proposal [AuthorProposal] the approved proposal
  # @return [Mail::Message] the email to be delivered
  def approval_notification(author_proposal)
    @proposal = author_proposal
    # Eager load author to avoid strict loading violation
    @author = author_proposal.author_id.present? ? Author.find(author_proposal.author_id) : nil

    mail(
      to: @proposal.submitter_email,
      subject: "Author Proposal Approved - #{@author.name}"
    )
  end

  # Sends rejection notification when admin rejects the proposal
  #
  # Includes:
  # - Admin feedback comment explaining rejection
  # - Encouragement to revise and resubmit
  # - Proposal ID for reference
  #
  # @param author_proposal [AuthorProposal] the rejected proposal
  # @return [Mail::Message] the email to be delivered
  def rejection_notification(author_proposal)
    @proposal = author_proposal
    # Eager load author to avoid strict loading violation
    @author = author_proposal.author_id.present? ? Author.find(author_proposal.author_id) : nil
    @admin_comment = author_proposal.admin_comment

    mail(
      to: @proposal.submitter_email,
      subject: "Author Proposal Feedback - ID ##{@proposal.id}"
    )
  end
end
