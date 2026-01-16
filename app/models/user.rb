# frozen_string_literal: true

# == Schema Information
#
# Table name: users
# Database name: primary
#
#  id              :integer          not null, primary key
#  email_address   :string           not null
#  name            :string           not null
#  password_digest :string           not null
#  role            :string           default("editor"), not null
#  status          :string           default("active"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#
class User < ApplicationRecord
  include User::Role
  include User::Bannable

  has_secure_password

  # Associations
  has_many :sessions, dependent: :destroy
  has_many :bans, dependent: :destroy

  # Validations
  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  # Normalize email to lowercase
  before_validation :normalize_email

  private

  def normalize_email
    self.email_address = email_address.downcase.strip if email_address.present?
  end
end
