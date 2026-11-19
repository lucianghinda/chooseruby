# frozen_string_literal: true

require "test_helper"

class ApplicationJobTest < ActiveJob::TestCase
  class EchoJob < ApplicationJob
    def perform(message)
      message
    end
  end

  test "application jobs use the configured adapter and serialize queued arguments" do
    assert_enqueued_with(job: EchoJob, args: [ "ready" ], queue: "default") do
      EchoJob.perform_later("ready")
    end
  end

  test "application job subclasses execute their work through Active Job" do
    assert_equal "ready", EchoJob.perform_now("ready")
  end
end
