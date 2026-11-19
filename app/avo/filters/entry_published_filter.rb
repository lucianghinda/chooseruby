# frozen_string_literal: true

# Filters admin entries by the selected public visibility states.
class Avo::Filters::EntryPublishedFilter < Avo::Filters::BooleanFilter
  self.name = "Published"

  def apply(_request, query, value)
    attributes = Selection.new(value, options.keys).attributes
    attributes.empty? ? query : query.where(attributes)
  end

  def options
    { "true" => "Published", "false" => "Unpublished" }
  end

  # Interprets Avo checkbox selections and legacy single-value filter URLs.
  class Selection
    def initialize(value, allowed_values)
      @value = value
      @allowed_values = allowed_values
    end

    def attributes
      case selected_values
      when [ "true" ] then { published: true }
      when [ "false" ] then { published: false }
      else {}
      end
    end

    private

    attr_reader :value, :allowed_values

    def selected_values
      return allowed_values.intersection([ value ]) unless value.is_a?(Hash)

      value.stringify_keys.slice(*allowed_values).select { |_state, enabled| enabled }.keys
    end
  end
end
