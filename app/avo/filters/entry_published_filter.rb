# frozen_string_literal: true

class Avo::Filters::EntryPublishedFilter < Avo::Filters::BooleanFilter
  self.name = "Published"

  STATES = { "true" => "Published", "false" => "Unpublished" }.freeze

  def apply(_request, query, value)
    # Avo posts the two checkboxes as a hash of states, while the same filter
    # coming off the query string arrives as a plain "true"/"false" string.
    states = value.try(:stringify_keys) || { value.to_s => true }
    checked = STATES.keys.select { |state| states[state] }

    # Checking both boxes, or neither, asks for every entry.
    return query unless checked.one?

    query.where(published: checked.first == "true")
  end

  def options
    STATES
  end
end
