# frozen_string_literal: true

# Author proposals arrive through the public form and are settled with the
# Approve and Reject actions, so Avo keeps them read only. The resource drops the
# controls that lead here; these override the routes behind them.
class Avo::AuthorProposalsController < Avo::ResourcesController
  READ_ONLY_NOTICE = "Author proposals are read only. Use the Approve and Reject actions."

  %i[new create edit update destroy].each do |write_action|
    define_method(write_action) do
      redirect_to resources_author_proposals_path, alert: READ_ONLY_NOTICE
    end
  end
end
