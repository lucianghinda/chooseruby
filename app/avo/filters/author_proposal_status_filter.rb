# frozen_string_literal: true

# Limits the admin proposal listing to a selected review status.
class Avo::Filters::AuthorProposalStatusFilter < Avo::Filters::SelectFilter
  self.name = "Status"

  def apply(_request, query, value)
    status = value.to_s.downcase

    return query unless options.key?(status)

    query.where(status: status)
  end

  def options
    {
      "pending" => "Pending",
      "approved" => "Approved",
      "rejected" => "Rejected"
    }
  end

  def default
    "pending"
  end
end
