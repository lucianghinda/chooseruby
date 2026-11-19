# frozen_string_literal: true

require "test_helper"
require "rake"
require "stringio"
require "tmpdir"

class MaintenanceTasksTest < ActiveSupport::TestCase
  TASK_DEFINITIONS = Rake.with_application do
    Rake::Task.define_task(:environment)
    Rake::Task.define_task("db:test:prepare")
    %w[annotate_rb fts rubyandrailsinfo users].each do |file|
      load File.expand_path("../../lib/tasks/#{file}.rake", __dir__)
    end
  end.tasks.to_h do |task|
    [ task.name, { prerequisites: task.prerequisites.freeze, actions: task.actions.freeze }.freeze ]
  end.freeze

  class ConsoleInput < StringIO
    def noecho
      yield self
    end
  end

  test "FTS creation creates missing tables and preserves existing contents" do
    connection = ActiveRecord::Base.connection
    connection.execute("DROP TABLE entries_fts")
    connection.execute("DROP TABLE authors_fts")

    output = invoke_task("fts:create")

    assert_includes connection.virtual_tables.map(&:first), "entries_fts"
    assert_includes connection.virtual_tables.map(&:first), "authors_fts"
    assert_includes output, "Created entries_fts table"
    assert_includes output, "Created authors_fts table"

    connection.execute("INSERT INTO entries_fts (entry_id, title) VALUES (123, 'Keep me')")
    output = invoke_task("fts:create")

    assert_equal "Keep me", connection.select_value("SELECT title FROM entries_fts WHERE entry_id = 123")
    assert_includes output, "entries_fts already exists"
    assert_includes output, "authors_fts already exists"
  end

  test "database test preparation creates FTS tables" do
    ActiveRecord::Base.connection.execute("DROP TABLE authors_fts")

    invoke_task("db:test:prepare")

    assert_includes ActiveRecord::Base.connection.virtual_tables.map(&:first), "authors_fts"
  end

  test "each reindex command restores its search records" do
    entry = Entry.create!(title: "Task indexing", url: "https://example.com/task-indexing", status: :approved)
    author = Author.create!(name: "Task Indexer")
    connection = ActiveRecord::Base.connection

    %w[fts:reindex_entries fts:reindex_authors fts:reindex_all].each do |task|
      connection.execute("DELETE FROM entries_fts")
      connection.execute("DELETE FROM authors_fts")

      output = invoke_task(task)

      unless task == "fts:reindex_authors"
        assert_equal entry.title, connection.select_value("SELECT title FROM entries_fts WHERE entry_id = #{entry.id}")
      end
      unless task == "fts:reindex_entries"
        assert_equal author.name, connection.select_value("SELECT name FROM authors_fts WHERE author_id = #{author.id}")
      end
      assert_match(/completed/, output)
    end
  end

  test "admin command creates an active administrator and never prints passwords" do
    output = with_console_input("NEW-ADMIN@example.com\nNew Admin\nsecret-password\nsecret-password\n") do
      invoke_task("users:create_admin")
    end

    user = User.strict_loading.find_by!(email_address: "new-admin@example.com")
    assert_predicate user, :admin?
    assert_predicate user, :active?
    assert user.authenticate("secret-password")
    assert_includes output, "Successfully created admin user: New Admin"
    refute_includes output, "secret-password"
  end

  test "admin command refuses mismatched passwords without creating a user" do
    output = capture_io do
      assert_no_difference "User.count" do
        error = assert_raises(SystemExit) do
          with_console_input("new-admin@example.com\nNew Admin\nfirst\nsecond\n") do
            run_task("users:create_admin")
          end
        end
        assert_equal 1, error.status
      end
    end.first
    assert_includes output, "Error: Passwords don't match"
  end

  test "admin command reports validation errors without creating a user" do
    output = capture_io do
      error = assert_raises(SystemExit) do
        with_console_input("invalid-email\nNew Admin\nsecret\nsecret\n") do
          run_task("users:create_admin")
        end
      end
      assert_equal 1, error.status
    end.first

    assert_includes output, "Failed to create user:"
    assert_includes output, "Email address is invalid"
    refute User.exists?(email_address: "invalid-email")
  end

  test "import commands convert and import files relative to the application root" do
    original_root = Rails.application.config.root
    Dir.mktmpdir do |directory|
      Rails.application.config.root = Pathname.new(directory)
      FileUtils.mkdir_p(Rails.root.join("tmp"))
      File.write(Rails.root.join("tmp/latest.sql"), <<~'SQL')
        COPY "public"."tags" ("id", "title", "slug") FROM stdin;
        91827	Task Imported Category	task-imported-category
        \.
      SQL

      invoke_task("rubyandrailsinfo:sql_to_yaml")
      assert_path_exists Rails.root.join("data/rubyandrailsinfo/tags.yml")

      invoke_task("rubyandrailsinfo:yaml_to_db")
      assert Category.exists?(name: "Task Imported Category")
    end
  ensure
    Rails.application.config.root = original_root
  end

  test "annotation tasks only load in development without the skip variable" do
    Rake.with_application do
      Rake::Task.define_task("db:migrate")
      DevelopmentAnnotations.new(environment: "development".inquiry, skip: nil).load_tasks
      assert_equal 1, Rake::Task["db:migrate"].actions.length
    end
    Rake.with_application do
      Rake::Task.define_task("db:migrate")
      DevelopmentAnnotations.new(environment: "development".inquiry, skip: "1").load_tasks
      assert_empty Rake::Task["db:migrate"].actions
    end
    Rake.with_application do
      Rake::Task.define_task("db:migrate")
      DevelopmentAnnotations.new(environment: "test".inquiry, skip: nil).load_tasks
      assert_empty Rake::Task["db:migrate"].actions
    end
  end

  private

  def invoke_task(name)
    capture_io { run_task(name) }.first
  end

  def run_task(name)
    Rake.with_application do
      TASK_DEFINITIONS.each do |task_name, definition|
        task = Rake::Task.define_task(task_name => definition.fetch(:prerequisites))
        definition.fetch(:actions).each { |action| task.enhance(&action) }
      end
      Rake::Task[name].invoke
    end
  end

  def with_console_input(content)
    original_input = $stdin
    $stdin = ConsoleInput.new(content)
    yield
  ensure
    $stdin = original_input
  end
end
