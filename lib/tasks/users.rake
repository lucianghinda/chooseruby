# frozen_string_literal: true

require "io/console"

namespace :users do
  desc "Create a new admin user"
  task create_admin: :environment do
    exit 1 unless AdminUserCreator.new.call
  end
end
