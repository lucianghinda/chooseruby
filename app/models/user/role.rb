# frozen_string_literal: true

# Editor/admin role and the permission checks that depend on it.
module User::Role
  extend ActiveSupport::Concern

  included do
    enum :role, %w[editor admin].index_by(&:itself), default: :editor
  end

  def can_administer?
    admin?
  end

  def can_edit?
    editor? || admin?
  end
end
