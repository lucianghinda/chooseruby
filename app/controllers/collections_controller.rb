# frozen_string_literal: true

class CollectionsController < ApplicationController
  before_action :load_collection, only: :show

  def index
    @collections = curated_collections_data
    @experience_tracks = experience_tracks_data
  end

  def show
    @categories = Category.order(:display_order, :name)
    @base_filters = @collection.fetch(:filters, {}).symbolize_keys
    override_filters = params.permit(:q, :level, :category).to_h.symbolize_keys
    merged_filters = @base_filters.merge(override_filters) do |_key, base, override|
      override.present? ? override : base
    end

    @directory_query = EntryDirectoryQuery.new(merged_filters)
    @entries = @directory_query.call.page(params[:page]).per(12)
  end

  private

  def load_collection
    slug = params[:id]
    @collection = curated_collections_data.find { |collection| collection[:slug] == slug }
    raise ActiveRecord::RecordNotFound, "Collection not found" unless @collection
  end
end
