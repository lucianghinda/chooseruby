# frozen_string_literal: true

# Finds entries carrying a selected tag in the admin listing.
class Avo::Filters::EntryTagsFilter < Avo::Filters::SelectFilter
  self.name = "Tags"

  def apply(_request, query, value)
    return query if value.blank?

    # Filter entries that have the selected tag in their tags array
    query.where("tags LIKE ? ESCAPE '\\'", tag_pattern(value))
  end

  def options
    # Get all unique tags from all entries
    @options ||= Entry.where.not(tags: nil)
         .pluck(:tags)
         .flatten
         .compact
         .uniq
         .sort
         .map { |tag| [ tag, tag.titleize ] }
         .to_h
  end

  private

  def tag_pattern(value)
    return unless options.key?(value)

    sanitized_value = ActiveRecord::Base.sanitize_sql_like(value)
    "%#{sanitized_value}%"
  end
end
