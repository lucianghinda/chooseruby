# frozen_string_literal: true

# Configures the admin form and listing for User records.
class Avo::Resources::User < Avo::BaseResource
  self.includes = []

  def fields
    identity_fields
    access_fields
    timestamp_fields
  end

  private

  def identity_fields
    field :id, as: :id
    field :email_address, as: :text, required: true
    field :name, as: :text, required: true
  end

  def access_fields
    field :password, as: :password, only_on: [ :new, :edit ], required: true, help: "Leave blank to keep current password"
    field :role, as: :select, enum: ::User.roles, required: true
    field :status, as: :select, enum: ::User.statuses, required: true
    field :sessions, as: :has_many
  end

  def timestamp_fields
    field :created_at, as: :date_time
    field :updated_at, as: :date_time
  end
end
