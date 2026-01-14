# frozen_string_literal: true

class Avo::Resources::RubyGem < Avo::BaseResource
  self.title = :display_name
  self.includes = [ :entry ]
  self.description = "Create a RubyGem first, then create an Entry and select this RubyGem as the entryable"

  def fields
    field :id, as: :id, link_to_record: true

    # Gem-specific information
    field :gem_name, as: :text, required: true, sortable: true, help: "Official gem name from RubyGems.org"
    field :rubygems_url, as: :text, help: "Link to RubyGems.org page"
    field :github_url, as: :text, help: "Link to GitHub repository"
    field :documentation_url, as: :text, help: "Link to documentation"
    field :downloads_count, as: :number, help: "Total downloads from RubyGems (optional)"
    field :current_version, as: :text, help: "Current gem version"

    # Association to base entry resource
    field :entry, as: :has_one,
          help: "After creating this RubyGem, go to Entries → New and select this RubyGem"

    # Timestamps
    field :created_at, as: :date_time, readonly: true, hide_on: [ :index ]
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end
end
