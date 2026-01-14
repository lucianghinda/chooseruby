# frozen_string_literal: true

class Avo::Filters::AuthorStatusFilter < Avo::Filters::SelectFilter
  self.name = "Status"

  def apply(request, query, value)
    case value
    when "approved"
      query.approved
    when "pending"
      query.pending
    else
      query
    end
  end

  def options
    {
      "Approved" => "approved",
      "Pending" => "pending"
    }
  end
end
