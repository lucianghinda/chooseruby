# frozen_string_literal: true

# Configures the admin form and listing for Community records.
class Avo::Resources::Community < Avo::BaseResource
  self.title = :display_name
  self.includes = [ :entry ]
  self.description = "Create a Community first, then create an Entry and select this Community as the entryable"

  def fields
    community_fields
    entry_fields
    timestamp_fields
  end

  private

  def community_fields
    field :id, as: :id, link_to_record: true
    field :platform, as: :text, required: true, help: "Platform (e.g., Discord, Slack, Forum, Reddit)"
    field :join_url, as: :text, required: true, help: "Direct link to join the community"
    field :member_count, as: :number, help: "Number of members (optional)"
    field :is_official, as: :boolean, help: "Is this an official Ruby community?"
  end

  def entry_fields
    field :entry, as: :has_one,
          help: "After creating this Community, go to Entries → New and select this Community"
  end

  def timestamp_fields
    field :created_at, as: :date_time, readonly: true, hide_on: [ :index ]
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end
end
