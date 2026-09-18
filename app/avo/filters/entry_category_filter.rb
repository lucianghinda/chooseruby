# frozen_string_literal: true

# Finds entries assigned to a selected category in the admin listing.
class Avo::Filters::EntryCategoryFilter < Avo::Filters::SelectFilter
  self.name = "Category"

  def apply(_request, query, value)
    category_id = value.to_s
    return query unless options.key?(category_id)

    # Keep association preloads separate from filtering, including polymorphic entryables.
    query.where(id: CategoriesEntry.where(category_id: category_id).select(:entry_id))
  end

  def options
    # Get all categories ordered by name
    @options ||= Category.order(:name).pluck(:id, :name).to_h.transform_keys(&:to_s)
  end
end
