# frozen_string_literal: true

require "io/console"

# Collects terminal credentials and creates an administrator with validation feedback.
class AdminUserCreation
  def initialize(input: $stdin, output: $stdout)
    @input = input
    @output = output
  end

  def call
    output.puts "Creating new admin user...", ""
    user = User.strict_loading.create!(read_attributes)
    output.puts "", "Successfully created admin user: #{user.name}", "Email: #{user.email_address}"
  rescue ActiveRecord::RecordInvalid => error
    report_invalid_user(error.record)
  end

  private

  attr_reader :input, :output

  def read_attributes
    attributes = { email_address: read_value("Email address: "), name: read_value("Name: ") }
    password = read_password
    attributes.merge(password:, password_confirmation: password, role: :admin, status: :active)
  end

  def report_invalid_user(user)
    output.puts "", "Failed to create user:"
    user.errors.full_messages.each { |message| output.puts "  - #{message}" }
    exit 1
  end

  def read_value(prompt)
    output.print prompt
    input.gets.chomp
  end

  def read_secret(prompt)
    output.print prompt
    value = input.noecho(&:gets).chomp
    output.puts ""
    value
  end

  def read_password
    password = read_secret("Password: ")
    confirmation = read_secret("Confirm password: ")
    return password if password == confirmation

    output.puts "Error: Passwords don't match"
    exit 1
  end
end
