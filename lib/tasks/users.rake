# frozen_string_literal: true

namespace :users do
  desc "Create a new admin user"
  task create_admin: :environment do
    AdminUserCreation.new.call
  end
end
