# frozen_string_literal: true

class Avo::Filters::EntryTagsFilter < Avo::Filters::SelectFilter
  self.name = "Tags"

  def apply(request, query, value)
    return query if value.blank?

    # Filter entries that have the selected tag in their tags array
    sanitized_value = ActiveRecord::Base.sanitize_sql_like(value)
    query.where("tags LIKE ?", "%#{sanitized_value}%")
  end

  def options
    # Get all unique tags from all entries
    Entry.where.not(tags: nil)
         .pluck(:tags)
         .flatten
         .compact
         .uniq
         .sort
         .map { |tag| [ tag.titleize, tag ] }
         .to_h
  end
end
