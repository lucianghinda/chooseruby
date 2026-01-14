# frozen_string_literal: true

class PagesController < ApplicationController
  def why_ruby
    @pillars = [
      {
        title: "Velocity without the overhead",
        description: "Rails 8 ships with built-in tooling—from Turbo and Solid Queue to Solid Cache—so teams deliver features quickly without maintaining a fleet of services.",
        icon: "⚡"
      },
      {
        title: "Curated ecosystem of gems",
        description: "Decades of community experience created best-in-class gems for authentication, background jobs, payments, and more. ChooseRuby surfaces the trustworthy options.",
        icon: "💎"
      },
      {
        title: "Human-friendly language",
        description: "Ruby’s expressiveness keeps code approachable, empowering small teams and solo founders to ship production software with confidence.",
        icon: "🤝"
      }
    ]

    @modern_highlights = [
      {
        name: "Rails 8 + Hotwire",
        description: "Build interactive experiences with server-rendered HTML, Turbo Streams, and Stimulus—no sprawling front-end stack required."
      },
      {
        name: "Solid Queue & Solid Cache",
        description: "Background jobs and caching without extra infrastructure. Store everything in SQLite for a fast, low-maintenance deployment."
      },
      {
        name: "Vibrant communities",
        description: "Active contributors, meetups, and online communities champion modern Ruby patterns and help newcomers skill up quickly."
      }
    ]
  end

  def mission
    @mission_points = [
      {
        title: "Surface the best of Ruby",
        description: "Curate gems, guides, and tools so developers can solve real problems faster than hunting across forums and GitHub."
      },
      {
        title: "Maintain ecosystem credibility",
        description: "Every submission goes through editorial review to make sure recommendations stay current, relevant, and production ready."
      },
      {
        title: "Champion the community",
        description: "Spotlight contributors and stories that demonstrate Ruby’s strengths, closing the perception gap for curious developers."
      }
    ]

    @personas = [
      { name: "Sarah", role: "Ruby Beginner", goal: "Find trusted guidance while building first projects." },
      { name: "Marcus", role: "Experienced Developer", goal: "Stay current with ecosystem changes and pick the right tools quickly." },
      { name: "Priya", role: "Language Explorer", goal: "Evaluate Ruby’s capabilities compared with other ecosystems." },
      { name: "Jordan", role: "Expert Contributor", goal: "Help quality resources reach the community and shape best practices." }
    ]
  end

  def roadmap
    @mvp_tracks = [
      {
        title: "Searchable directory",
        description: "Deliver a responsive, filterable resource directory so developers can discover the right gems and guides instantly."
      },
      {
        title: "Resource profiles",
        description: "Compose rich profiles with descriptions, use cases, and related resources to help developers evaluate at a glance."
      },
      {
        title: "Contribution workflow",
        description: "Collect submissions, route them through review, and surface curated additions in the public directory."
      }
    ]

    @roadmap_pillars = [
      {
        title: "Phase 1: Foundation",
        items: [
          "Public directory with search, filters, and responsive cards.",
          "Individual resource pages with context, links, and related items.",
          "Category navigation for domains like Testing, Background Jobs, and Authentication."
        ]
      },
      {
        title: "Phase 2: Community",
        items: [
          "Community submission form with validation and curation queue.",
          "Experience level filtering and beginner-friendly onboarding collections.",
          "\"Why Ruby?\" showcase demonstrating modern Rails capabilities."
        ]
      },
      {
        title: "Phase 3: Engagement",
        items: [
          "Resource type organization (gems, books, tutorials, podcasts) with dedicated browse pages.",
          "Enhanced search facets and sorting for power users.",
          "Foundation for user accounts, saved resources, and ratings."
        ]
      }
    ]
  end
end
