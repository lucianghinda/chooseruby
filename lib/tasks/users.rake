# frozen_string_literal: true

require "io/console"

namespace :users do
  desc "Create a new admin user"
  task create_admin: :environment do
    puts "Creating new admin user..."
    puts ""

    print "Email address: "
    email = $stdin.gets.chomp

    print "Name: "
    name = $stdin.gets.chomp

    print "Password: "
    password = $stdin.noecho(&:gets).chomp
    puts ""

    print "Confirm password: "
    password_confirmation = $stdin.noecho(&:gets).chomp
    puts ""

    unless password == password_confirmation
      puts "Error: Passwords don't match"
      exit 1
    end

    begin
      user = User.create!(
        email_address: email,
        password: password,
        password_confirmation: password,
        name: name,
        role: :admin,
        status: :active
      )

      puts ""
      puts "Successfully created admin user: #{user.name}"
      puts "Email: #{user.email_address}"
    rescue ActiveRecord::RecordInvalid => e
      puts ""
      puts "Failed to create user:"
      e.record.errors.full_messages.each { |error| puts "  - #{error}" }
      exit 1
    end
  end
end
