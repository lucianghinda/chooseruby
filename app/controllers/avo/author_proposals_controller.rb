# frozen_string_literal: true

class Avo::AuthorProposalsController < Avo::ResourcesController
  # This controller handles the Avo admin interface for AuthorProposal resources
  # Proposals are created via public forms, not through Avo admin

  # Disable create/edit/delete actions - only allow index and show
  def authorize_action(action)
    return false if [ :create, :new, :edit, :update, :destroy ].include?(action)

    true
  end
end
