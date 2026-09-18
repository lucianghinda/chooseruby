# frozen_string_literal: true

# tailwindcss-rails makes test:prepare depend on tailwindcss:build, whose :environment
# prerequisite boots the app inside the test process before test_helper.rb starts
# SimpleCov. Everything loaded during that boot (Avo actions, controller concerns) would
# then be reported as uncovered. Build the stylesheet in a subprocess instead, the same
# way test:db handles db:test:prepare.
if Rake::Task.task_defined?("test:prepare")
  Rake::Task["test:prepare"].prerequisites.delete("tailwindcss:build")
  Rake::Task["test:prepare"].enhance do
    system("bin/rails", "tailwindcss:build", exception: true)
  end
end
