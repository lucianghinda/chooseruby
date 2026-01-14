# frozen_string_literal: true

class Avo::Filters::EntryCategoryFilter < Avo::Filters::SelectFilter
  self.name = "Category"

  def apply(request, query, value)
    return query if value.blank?

    # Filter entries that belong to the selected category
    query.joins(:categories).where(categories: { id: value })
  end

  def options
    # Get all categories ordered by name
    Category.order(:name).pluck(:name, :id).to_h
  end
end
