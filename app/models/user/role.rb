# frozen_string_literal: true

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
