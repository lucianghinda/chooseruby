# frozen_string_literal: true

class Avo::Filters::EntryPublishedFilter < Avo::Filters::BooleanFilter
  self.name = "Published"

  def apply(request, query, value)
    selection = value.is_a?(Hash) ? value.stringify_keys : {}

    return query.where(published: true) if selection["true"] && !selection["false"]
    return query.where(published: false) if selection["false"] && !selection["true"]
    return query.where(published: true) if value == "true"
    return query.where(published: false) if value == "false"

    query
  end

  def options
    { "true" => "Published", "false" => "Unpublished" }
  end
end
