# frozen_string_literal: true

# Collects successful proposal reviews and individual failures for the admin response.
class Avo::ProposalReviewResult
  def initialize
    @success_count = 0
    @errors = []
  end

  def approve(proposal)
    proposal.approve!
    record_success
  rescue StandardError => exception
    record_failure(proposal, exception)
  end

  def reject(proposal, admin_comment)
    proposal.reject!(admin_comment: admin_comment)
    record_success
  rescue StandardError => exception
    record_failure(proposal, exception)
  end

  def success?
    errors.empty?
  end

  def message(verb)
    return failure_message(verb) unless success?

    "#{@success_count} #{'proposal'.pluralize(@success_count)} #{verb} successfully!"
  end

  private

  attr_reader :errors

  def record_success
    @success_count += 1
  end

  def record_failure(proposal, exception)
    errors << "Proposal ##{proposal.id}: #{exception.message}"
  end

  def failure_message(verb)
    "#{@success_count} #{verb}, #{errors.count} failed: #{errors.join('; ')}"
  end
end
