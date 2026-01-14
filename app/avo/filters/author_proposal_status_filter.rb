# frozen_string_literal: true

class Avo::Filters::AuthorProposalStatusFilter < Avo::Filters::SelectFilter
  self.name = "Status"

  def apply(request, query, value)
    status = value.to_s.downcase

    case status
    when "pending"
      query.pending
    when "approved"
      query.approved
    when "rejected"
      query.rejected
    else
      query
    end
  end

  def options
    {
      "Pending" => "pending",
      "Approved" => "approved",
      "Rejected" => "rejected"
    }
  end

  def default
    "pending"
  end
end
