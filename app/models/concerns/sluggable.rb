# frozen_string_literal: true

# Generates a unique, URL-friendly slug from a source attribute before
# validation, appending "-1", "-2", ... on collision within the class.
#
#   class Author < ApplicationRecord
#     include Sluggable
#     sluggable_from :name
#   end
module Sluggable
  extend ActiveSupport::Concern

  class_methods do
    def sluggable_from(attribute)
      define_method(:slug_source) { send(attribute) }
      private :slug_source

      before_validation :generate_slug,
        if: -> { slug_source.present? && (slug.blank? || send(:"#{attribute}_changed?")) }
    end
  end

  private

  def generate_slug
    self.slug = unique_slug(slug_source.parameterize)
  end

  def unique_slug(base_slug)
    candidate = base_slug
    counter = 1

    while self.class.where(slug: candidate).where.not(id: id).exists?
      candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    candidate
  end
end
