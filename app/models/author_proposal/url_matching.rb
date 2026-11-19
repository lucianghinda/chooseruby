# frozen_string_literal: true

# Normalizes a proposal's resource_url and tries to match it to an existing
# Entry, so the review UI can show "this looks like an existing resource".
module AuthorProposal::UrlMatching
  extend ActiveSupport::Concern

  class_methods do
    # Normalizes a URL for consistent matching.
    # Handles: whitespace, http/https, trailing slashes, www prefix, case.
    def normalize_url(url)
      return nil if url.blank?

      url.strip.downcase
        .sub(%r{\Ahttps://}, "http://")
        .sub(%r{\Ahttp://www\.}, "http://")
        .sub(%r{/\z}, "")
    end
  end

  included do
    before_validation :normalize_and_match_resource_url, if: -> { resource_url.present? }
  end

  private

  # Normalizes resource_url and attempts to match with existing Entry.
  # Stores original URL and sets matched_entry_id if found.
  def normalize_and_match_resource_url
    return if resource_url.blank?

    self.original_resource_url = resource_url.dup
    self.resource_url = self.class.normalize_url(resource_url)
    match_entry_by_url
  end

  # Searches for matching Entry by normalized URL.
  # Sets matched_entry_id if exact match found.
  def match_entry_by_url
    matched = Entry.find_by(
      "REPLACE(REPLACE(LOWER(TRIM(url)), 'https://', 'http://'), 'www.', '') = ?",
      resource_url.sub(%r{/\z}, "")
    )

    self.matched_entry_id = matched&.id
  end
end
