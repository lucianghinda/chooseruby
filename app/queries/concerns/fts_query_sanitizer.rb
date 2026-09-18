# frozen_string_literal: true

# Shared by AuthorSearchQuery and EntryDirectoryQuery, which both build an
# FTS5 MATCH query from free-text user input (was two copies of this exact
# logic - see docs/llms/development.md's over-engineering pass).
module FtsQuerySanitizer
  # Sanitizes an FTS5 query string: preserves quoted phrases for exact
  # matching, strips FTS5 special characters ("(", ")", "-", "'") from other
  # words, and adds a wildcard suffix to each for partial matching.
  #
  # Examples:
  #   "rails" => "rails*"
  #   "rails framework" => "rails* framework*"
  #   '"web framework"' => '"web framework"'
  #   'rails "web framework"' => 'rails* "web framework"'
  def sanitize_fts_query(query_string)
    return "" if query_string.blank?

    phrases = []
    query_without_phrases = query_string.gsub(/"([^"]*)"/) do |match|
      phrases << match
      "__PHRASE_#{phrases.length - 1}__"
    end

    processed_words = query_without_phrases.split(/\s+/).map do |word|
      next word if word.start_with?("__PHRASE_")

      cleaned = word.gsub(/[()\-']/, "").gsub(/\*+\z/, "")
      cleaned.present? ? "#{cleaned}*" : ""
    end.reject(&:blank?)

    result = processed_words.join(" ")
    phrases.each_with_index { |phrase, index| result = result.gsub("__PHRASE_#{index}__", phrase) }
    result
  end
end
