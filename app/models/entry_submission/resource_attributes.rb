# frozen_string_literal: true

# Restricts delegated resource attributes to the fields accepted by its type.
class EntrySubmission::ResourceAttributes
  FIELDS = {
    "RubyGem" => %i[gem_name github_url documentation_url rubygems_url current_version downloads_count],
    "Book" => %i[isbn publisher publication_year page_count format purchase_url],
    "Course" => %i[platform instructor duration_hours currency is_free enrollment_url],
    "Tutorial" => %i[reading_time_minutes publication_date author_name platform],
    "Article" => %i[reading_time_minutes publication_date author_name platform],
    "Tool" => %i[tool_type github_url documentation_url license is_open_source],
    "Podcast" => %i[host episode_count frequency rss_feed_url spotify_url apple_podcasts_url],
    "Community" => %i[platform join_url member_count is_official]
  }.transform_values(&:freeze).freeze

  def initialize(attributes)
    @attributes = attributes
  end

  def build
    resource_type.constantize.new(resource_attributes)
  end

  private

  attr_reader :attributes

  def resource_type
    type = attributes[:resource_type]
    raise ArgumentError, "Unknown resource type: #{type}" unless FIELDS.key?(type)

    type
  end

  def resource_attributes
    fields = FIELDS.fetch(resource_type)
    attributes.slice(*fields).tap do |typed_attributes|
      typed_attributes[:price_cents] = price_in_cents if priced_course?
    end
  end

  def priced_course?
    resource_type == "Course" && attributes[:price].present?
  end

  def price_in_cents
    (attributes[:price].to_f * 100).to_i
  end
end
