# frozen_string_literal: true

# Limits the admin author listing to a selected approval status.
class Avo::Filters::AuthorStatusFilter < Avo::Filters::SelectFilter
  self.name = "Status"

  def apply(_request, query, value)
    return query unless options.key?(value)

    query.where(status: value)
  end

  def options
    {
      "approved" => "Approved",
      "pending" => "Pending"
    }
  end
end
