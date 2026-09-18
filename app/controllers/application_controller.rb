# frozen_string_literal: true

# Base controller: browser support, auth, and shared view data every
# controller needs (see AGENTS.md - controllers stay thin, logic lives on models).
class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Was copy-pasted into 4 actions across 3 controllers - see
  # docs/llms/development.md's over-engineering pass.
  rescue_from ActiveRecord::RecordNotFound do
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  end

  # Authentication and authorization
  include SetCurrentRequest
  include BlockBannedRequests
  include Authentication
  include Authorization

  helper_method :curated_collections_data, :experience_tracks_data

  # In test, ActiveSupport::TestCase already wraps every test (controller,
  # integration, or otherwise) in a single Prosopite.scan/finish - see
  # test/test_helper.rb. Nesting this around_action inside that breaks
  # Prosopite's state, so skip it there; it still runs for real dev-server
  # requests.
  if Rails.env.development?
    around_action :n_plus_one_detection

    def n_plus_one_detection
      Prosopite.scan
      yield
    ensure
      Prosopite.finish
    end
  end

  private

  def curated_collections_data
    [
      {
        title: "Build Faster with Hotwire",
        description: "Discover the modern Rails patterns behind Turbo, Stimulus, and CableReady. Ship interactive experiences without heavy JavaScript.",
        icon: "⚡",
        slug: "hotwire-speed",
        filters: { q: "hotwire" }
      },
      {
        title: "Production-Ready Rails 8",
        description: "Recommended gems, background job patterns, and deployment guides for taking a Rails 8 application to production with confidence.",
        icon: "🚀",
        slug: "rails-8-production",
        filters: { q: "rails 8", level: "intermediate" }
      },
      {
        title: "Level Up Your Testing",
        description: "Battle-tested testing frameworks, factory patterns, and coverage strategies used by experienced Rubyists.",
        icon: "🧪",
        slug: "testing-suite",
        filters: { q: "testing", category: "testing" }
      },
      {
        title: "Ruby for Career Switchers",
        description: "Structured learning paths, bootcamp-friendly resources, and real-world project ideas for newcomers to the ecosystem.",
        icon: "🎯",
        slug: "career-switch",
        filters: { level: "beginner" }
      }
    ]
  end

  def experience_tracks_data
    [
      {
        level: "Beginner",
        tagline: "Your Rails starting point",
        description: "Curated tutorials, sample apps, and learn-by-doing guides that make fundamentals stick.",
        accent: "bg-emerald-500/10 text-emerald-600"
      },
      {
        level: "Intermediate",
        tagline: "Ship features faster",
        description: "Best-practice architecture tips, service objects, background jobs, and security checklists.",
        accent: "bg-sky-500/10 text-sky-600"
      },
      {
        level: "Advanced",
        tagline: "Scale and lead",
        description: "Performance tuning, scalability patterns, and leadership resources for senior Rubyists.",
        accent: "bg-rose-500/10 text-rose-600"
      }
    ]
  end
end
