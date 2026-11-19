# frozen_string_literal: true

# Provides admin endpoints for author proposals.
class Avo::AuthorProposalsController < Avo::ResourcesController
  # This controller handles the Avo admin interface for AuthorProposal resources
  # Proposals are created via public forms, not through Avo admin

  # Disable create/edit/delete actions - only allow index and show
  def authorize_action(record, action = nil)
    requested_action = (action.presence || action_name).to_sym
    return head :forbidden if [ :create, :new, :edit, :update, :destroy ].include?(requested_action)

    super
  end
end
