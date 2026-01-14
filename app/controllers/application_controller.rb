# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Authentication and authorization
  include SetCurrentRequest
  include BlockBannedRequests
  include Authentication
  include Authorization

  helper_method :curated_collections_data, :experience_tracks_data

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
