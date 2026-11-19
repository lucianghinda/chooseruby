# frozen_string_literal: true

require "test_helper"

# Drives the project's own rake tasks. `bin/rails test` loads the .rake files but
# never runs the task bodies, so every one of them was unobserved.
class RakeTasksTest < ActiveSupport::TestCase
  def setup
    Rails.application.load_tasks unless Rake::Task.task_defined?("fts:create")
  end

  def run_task(name)
    task = Rake::Task[name]
    task.reenable
    capture_io { task.invoke }.first
  end

  # --- fts -----------------------------------------------------------------

  test "fts:create creates the tables when they are missing" do
    connection = ActiveRecord::Base.connection
    connection.execute("DROP TABLE IF EXISTS entries_fts")
    connection.execute("DROP TABLE IF EXISTS authors_fts")

    run_task("fts:create")

    assert fts_table?("entries_fts")
    assert fts_table?("authors_fts")
  end

  test "fts:create runs again on tables that already exist" do
    run_task("fts:create")

    run_task("fts:create")

    assert fts_table?("entries_fts")
    assert fts_table?("authors_fts")
  end

  test "the reindex tasks hand off to the reindexer" do
    { "fts:reindex_all" => :reindex_all,
      "fts:reindex_entries" => :reindex_entries,
      "fts:reindex_authors" => :reindex_authors }.each do |task_name, expected|
      reindexer = Recorder.new

      with_stubbed_new(FtsReindexer, -> { reindexer }) { run_task(task_name) }

      assert_equal [ expected ], reindexer.calls
    end
  end

  test "db:test:prepare is enhanced to create the FTS5 tables" do
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS entries_fts")

    # Only the appended action; running db:test:prepare itself would drop the
    # database this test is using.
    Rake::Task["fts:create"].reenable
    capture_io { Rake::Task["db:test:prepare"].actions.last.call }

    assert fts_table?("entries_fts")
  end

  # --- annotate_rb ---------------------------------------------------------

  # Ruby's Coverage keeps only the last load of a file, so the skip branch of the
  # environment guard cannot be recorded next to this one.
  test "the annotate_rb rake tasks are loaded in development" do
    with_rails_env("development") do
      load Rails.root.join("lib/tasks/annotate_rb.rake").to_s
    end

    assert defined?(AnnotateRb::Core), "the gem's rake tasks are loaded in development"
  end

  # --- rubyandrailsinfo ----------------------------------------------------

  test "rubyandrailsinfo:sql_to_yaml converts the dump into the data directory" do
    converter = Recorder.new
    args = nil

    with_stubbed_new(Imports::Rubyandrailsinfo::SqlToYamlConverter, ->(**kwargs) { args = kwargs; converter }) do
      run_task("rubyandrailsinfo:sql_to_yaml")
    end

    assert_equal Rails.root.join("tmp/latest.sql"), args[:sql_file]
    assert_equal Rails.root.join("data/rubyandrailsinfo"), args[:output_dir]
    assert_equal [ :convert_all ], converter.calls
  end

  test "rubyandrailsinfo:yaml_to_db imports the data directory" do
    importer = Recorder.new
    args = nil

    with_stubbed_new(Imports::Rubyandrailsinfo::YamlImporter, ->(**kwargs) { args = kwargs; importer }) do
      run_task("rubyandrailsinfo:yaml_to_db")
    end

    assert_equal Rails.root.join("data/rubyandrailsinfo"), args[:yaml_dir]
    assert_equal [ :import_all ], importer.calls
  end

  # --- users ---------------------------------------------------------------

  test "users:create_admin creates an admin from the answers it is given" do
    with_stdin([ "new-admin@test.com", "New Admin", "secret123", "secret123" ]) do
      output = run_task("users:create_admin")

      assert_match "Successfully created admin user: New Admin", output
      assert_match "Email: new-admin@test.com", output
    end

    user = User.find_by(email_address: "new-admin@test.com")
    assert_predicate user, :admin?
    assert_predicate user, :active?
  end

  test "users:create_admin refuses when the two passwords differ" do
    with_stdin([ "mismatch@test.com", "Mismatch", "secret123", "different" ]) do
      error = assert_raises(SystemExit) { run_task("users:create_admin") }

      assert_equal 1, error.status
    end

    assert_nil User.find_by(email_address: "mismatch@test.com")
  end

  test "users:create_admin reports validation errors and fails" do
    with_stdin([ users(:admin).email_address, "Duplicate", "secret123", "secret123" ]) do
      out, = capture_io do
        error = assert_raises(SystemExit) { Rake::Task["users:create_admin"].tap(&:reenable).invoke }
        assert_equal 1, error.status
      end

      assert_match "Failed to create user:", out
    end
  end

  private

  def with_rails_env(name, &block)
    original = Rails.env
    Rails.env = name
    block.call
  ensure
    Rails.env = original
  end

  # Minitest 6 dropped Object#stub, and the real converter and importer read and
  # write files the rake task points them at.
  def with_stubbed_new(klass, replacement, &block)
    original = klass.method(:new)
    klass.define_singleton_method(:new) { |**kwargs| kwargs.empty? ? replacement.call : replacement.call(**kwargs) }
    block.call
  ensure
    klass.define_singleton_method(:new, original)
  end

  def fts_table?(name)
    ActiveRecord::Base.connection
      .select_values("SELECT name FROM sqlite_master WHERE name = '#{name}'")
      .any?
  end

  # $stdin.gets and $stdin.noecho(&:gets) read the answers in order.
  def with_stdin(answers, &block)
    original = $stdin
    $stdin = ScriptedStdin.new(answers)
    block.call
  ensure
    $stdin = original
  end

  # Stands in for the converter and the importer; the rake task only has to
  # build them with the right arguments and call them once.
  class Recorder
    attr_reader :calls

    def initialize
      @calls = []
    end

    def method_missing(name, ...)
      @calls << name
      nil
    end

    def respond_to_missing?(*) = true
  end

  class ScriptedStdin
    def initialize(answers)
      @answers = answers
    end

    def gets
      "#{@answers.shift}\n"
    end

    def noecho
      yield self
    end
  end
end
