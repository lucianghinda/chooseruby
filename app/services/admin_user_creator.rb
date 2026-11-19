# frozen_string_literal: true

# Walks an operator through creating an admin user on the console.
#
# Reads the answers from `input` and reports on `output`, so the rake task stays a
# single call and the conversation can be driven by a test.
class AdminUserCreator
  QUESTIONS = { email_address: "Email address", name: "Name" }.freeze

  def initialize(input: $stdin, output: $stdout)
    @input = input
    @output = output
  end

  # @return [User, nil] the new admin, or nil when the answers were refused
  def call
    @output.puts "Creating new admin user..."
    attributes = ask_for_attributes

    return refuse("Passwords don't match") unless attributes[:password] == ask_for_confirmation

    create_admin(attributes)
  end

  private

  def ask_for_attributes
    answers = QUESTIONS.transform_values { |question| ask(question) }
    answers.merge(password: ask_secretly("Password"))
  end

  def ask_for_confirmation
    ask_secretly("Confirm password")
  end

  def create_admin(attributes)
    announce(User.create!(**attributes, password_confirmation: attributes[:password], role: :admin, status: :active))
  rescue ActiveRecord::RecordInvalid => exception
    refuse("Failed to create user:", exception.record.errors.full_messages)
  end

  def announce(user)
    @output.puts ""
    @output.puts "Successfully created admin user: #{user.name}"
    @output.puts "Email: #{user.email_address}"
    user
  end

  def refuse(headline, details = [])
    @output.puts ""
    @output.puts headline
    details.each { |detail| @output.puts "  - #{detail}" }
    nil
  end

  def ask(question)
    @output.print "#{question}: "
    @input.gets.chomp
  end

  def ask_secretly(question)
    @output.print "#{question}: "
    answer = @input.noecho(&:gets).chomp
    @output.puts ""
    answer
  end
end
