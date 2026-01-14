# frozen_string_literal: true

module Authorization
  extend ActiveSupport::Concern

  included do
    helper_method :can_administer?
  end

  private

  def can_administer?
    current_user&.can_administer?
  end

  def ensure_can_administer
    unless can_administer?
      redirect_to root_path, alert: "You are not authorized to access this page"
    end
  end
end
