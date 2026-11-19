# frozen_string_literal: true

# Registers migration annotations only for development sessions that have not opted out.
class DevelopmentAnnotations
  def initialize(environment: Rails.env, skip: ENV["ANNOTATERB_SKIP_ON_DB_TASKS"])
    @enabled = environment.development? && !skip
  end

  def load_tasks
    return unless @enabled

    require "annotate_rb"
    AnnotateRb::Core.load_rake_tasks
  end
end
