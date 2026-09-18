# frozen_string_literal: true

class Avo::Filters::EntryPublishedFilter < Avo::Filters::BooleanFilter
  self.name = "Published"

  def apply(request, query, value)
    selection = value.stringify_keys

    return query.where(published: true) if selection["true"] && !selection["false"]
    return query.where(published: false) if selection["false"] && !selection["true"]

    query
  end

  def options
    { "true" => "Published", "false" => "Unpublished" }
  end
end
