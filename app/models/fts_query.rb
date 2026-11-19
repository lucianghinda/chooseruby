# frozen_string_literal: true

# A reader's search input, rewritten as an SQLite FTS5 MATCH expression.
#
# Quoted phrases are kept verbatim so that FTS5 matches them exactly. Every
# other word loses the characters FTS5 would read as syntax and gains a
# wildcard suffix, so that typing a prefix already finds the resource.
#
# Examples:
#   FtsQuery.new("matz").to_s                       # => "matz*"
#   FtsQuery.new("david hansson").to_s              # => "david* hansson*"
#   FtsQuery.new('"Yukihiro Matsumoto"').to_s       # => '"Yukihiro Matsumoto"'
#   FtsQuery.new('david "heinemeier hansson"').to_s # => 'david* "heinemeier hansson"'
class FtsQuery
  # Characters FTS5 reads as syntax, and that a plain search word must not carry
  IGNORED_CHARACTERS = /[()\-]/

  # A quoted phrase, which is searched for exactly as it was typed
  PHRASE = /"[^"]*"/

  PLACEHOLDER_PREFIX = "__PHRASE_"
  PLACEHOLDER = /#{PLACEHOLDER_PREFIX}(\d+)__/
  TRAILING_WILDCARDS = /\*+$/

  # @param text [String] the raw search input
  # @param ignored_characters [Regexp] characters stripped from non-phrase words
  def initialize(text, ignored_characters: IGNORED_CHARACTERS)
    @text = text.to_s
    @ignored_characters = ignored_characters
    @phrases = @text.scan(PHRASE)
  end

  # @return [String] the MATCH expression, empty when there is nothing to search for
  def to_s
    restore_phrases(search_words.join(" "))
  end

  private

  # Every word of the input, phrases held aside as placeholders, wildcarded
  def search_words
    text_without_phrases.split(/\s+/).map { |word|
      word.start_with?(PLACEHOLDER_PREFIX) ? word : wildcarded(word)
    }.reject(&:blank?)
  end

  # The input with every quoted phrase swapped for a placeholder token, so that
  # phrases come through the word-by-word rewriting untouched
  def text_without_phrases
    index = -1
    @text.gsub(PHRASE) { "#{PLACEHOLDER_PREFIX}#{index += 1}__" }
  end

  def wildcarded(word)
    cleaned = word.gsub(@ignored_characters, "").gsub(TRAILING_WILDCARDS, "")
    cleaned.present? ? "#{cleaned}*" : ""
  end

  def restore_phrases(expression)
    expression.gsub(PLACEHOLDER) { |placeholder| @phrases[Regexp.last_match(1).to_i] || placeholder }
  end
end
