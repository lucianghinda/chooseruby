# frozen_string_literal: true

class Avo::Resources::User < Avo::BaseResource
  self.includes = []

  def fields
    field :id, as: :id
    field :email_address, as: :text, required: true
    field :name, as: :text, required: true
    field :password, as: :password, only_on: [ :new, :edit ], required: true, help: "Leave blank to keep current password"
    field :role, as: :select, enum: ::User.roles, required: true
    field :status, as: :select, enum: ::User.statuses, required: true
    field :sessions, as: :has_many
    field :created_at, as: :date_time
    field :updated_at, as: :date_time
  end
end
