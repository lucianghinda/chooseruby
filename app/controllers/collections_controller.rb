# frozen_string_literal: true

# Applies curated search defaults to public resource collections.
class CollectionsController < ApplicationController
  def index
    render :index, locals: { collections: curated_collections_data, experience_tracks: experience_tracks_data }
  end

  def show
    collection = find_collection
    query = EntryDirectoryQuery.new(collection_filters(collection))
    render :show, locals: {
      collection: collection, directory_query: query,
      categories: Category.strict_loading.order(:display_order, :name),
      entries: query.call.page(params[:page]).per(12)
    }
  end

  private

  def collection_filters(collection)
    defaults = collection.fetch(:filters, {}).symbolize_keys
    overrides = params.permit(:q, :level, :category).to_h.symbolize_keys.compact_blank
    defaults.merge(overrides)
  end

  def find_collection
    slug = params[:id]
    curated_collections_data.find { |collection| collection[:slug] == slug } ||
      raise(ActiveRecord::RecordNotFound, "Collection not found")
  end
end
