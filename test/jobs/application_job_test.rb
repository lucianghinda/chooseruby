# frozen_string_literal: true

require "test_helper"

# ApplicationJob has an empty body; the only behaviour it carries is being the
# Active Job base class the application's jobs inherit from.
class ApplicationJobTest < ActiveJob::TestCase
  class RecordingJob < ApplicationJob
    queue_as :default

    cattr_accessor :performed_with, default: []

    def perform(value)
      self.class.performed_with << value
    end
  end

  setup { RecordingJob.performed_with = [] }

  test "is an Active Job base class" do
    assert_operator ApplicationJob, :<, ActiveJob::Base
  end

  test "descendants can be enqueued and performed" do
    assert_enqueued_with(job: RecordingJob, args: [ "hello" ]) do
      RecordingJob.perform_later("hello")
    end

    perform_enqueued_jobs

    assert_equal [ "hello" ], RecordingJob.performed_with
  end
end
