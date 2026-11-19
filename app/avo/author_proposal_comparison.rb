# frozen_string_literal: true

# Presents the before-and-after details of an author proposal for admin review.
class Avo::AuthorProposalComparison
  def initialize(proposal)
    @proposal = proposal
  end

  def new_author?
    valid? && proposal.new_author_proposal?
  end

  def type
    return "" unless valid?

    new_author? ? "New Author" : "Edit Existing Author"
  end

  def summary
    return "" unless valid?

    [ author_summary, resource_summary, links_summary, bio_summary, description_summary ].compact.join("\n")
  end

  private

  attr_reader :proposal

  delegate :author, to: :proposal

  def valid?
    proposal.is_a?(::AuthorProposal)
  end

  def author_summary
    new_author? ? "Creating new author: #{proposal.author_name}" : "Editing author: #{author&.name}"
  end

  def resource_summary
    return unless proposal.has_resource_proposal?

    if proposal.matched_entry?
      "\nResource: Matched entry ##{proposal.matched_entry_id} - #{proposal.matched_entry&.title}"
    else
      "\nResource: Unmatched URL - #{proposal.resource_url}"
    end
  end

  def links_summary
    return unless proposal.has_link_updates?

    changes = proposal.link_updates.map { |field, url| link_change(field, url) }
    [ "\nLink Updates:", *changes ].join("\n")
  end

  def link_change(field, url)
    current = author&.public_send(field)
    "  - #{field}: #{current.presence || '(blank)'} → #{url}"
  end

  def bio_summary
    proposed = proposal.bio_text
    return if proposed.blank?

    "\nBio:\n  Current: #{author&.bio.presence || '(blank)'}\n  Proposed: #{proposed}"
  end

  def description_summary
    proposed = proposal.description_text
    return if proposed.blank?

    # Author has no description attribute; this is a proposed addition only.
    "\nDescription:\n  Current: (blank)\n  Proposed: #{proposed}"
  end
end
