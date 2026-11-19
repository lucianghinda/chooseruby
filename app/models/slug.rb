# frozen_string_literal: true

# A URL-friendly identifier derived from a human readable source string.
#
# The slug knows how to make itself unique: it asks the records that already own
# a slug whether the candidate is taken, and appends an incrementing counter
# until it finds one that is free.
#
# Usage:
#   Slug.new("Yukihiro Matsumoto", taken_by: Author.where.not(id: id)).to_s
#   # => "yukihiro-matsumoto", or "yukihiro-matsumoto-1" when that name is taken
class Slug
  # @param source [String] the human readable text the slug is derived from
  # @param taken_by [ActiveRecord::Relation] the records a candidate must not collide with
  def initialize(source, taken_by:)
    @base = source.parameterize
    @taken_by = taken_by
  end

  # @return [String] the first candidate slug nobody else owns
  def to_s
    return @base if available?(@base)

    numbered_candidates.find { |candidate| available?(candidate) }
  end

  private

  def numbered_candidates
    (1..).lazy.map { |counter| "#{@base}-#{counter}" }
  end

  def available?(candidate)
    !@taken_by.exists?(slug: candidate)
  end
end
