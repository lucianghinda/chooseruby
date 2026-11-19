# frozen_string_literal: true

# Preserves quoted phrases while adding prefix matching to ordinary search words.
class FtsQuery
  def initialize(query, ignored_characters: /[()\-]/)
    @query = query
    @ignored_characters = ignored_characters
    @phrases = []
  end

  def call
    phrases.clear
    words = placeholder_query.split.map { |word| wildcard(word) }.reject(&:blank?)
    phrases.each_with_index.reduce(words.join(" ")) do |result, (phrase, index)|
      result.gsub("__PHRASE_#{index}__", phrase)
    end
  end

  private

  attr_reader :query, :ignored_characters, :phrases

  def placeholder_query
    query.gsub(/"[^"]*"/) do |phrase|
      phrases << phrase
      "__PHRASE_#{phrases.length - 1}__"
    end
  end

  def wildcard(word)
    return word if word.start_with?("__PHRASE_")

    cleaned = clean_word(word)
    "#{cleaned}*" if cleaned.present?
  end

  def clean_word(word)
    word.gsub(ignored_characters, "").sub(/\*+$/, "")
  end
end
