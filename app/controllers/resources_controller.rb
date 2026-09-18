# frozen_string_literal: true

# Presents visible resource details and related recommendations.
class ResourcesController < ApplicationController
  def index
    query = EntryDirectoryQuery.new(params.permit(:q, :level, :type, :sort).to_h)
    render :index, locals: {
      categories: Category.strict_loading.order(:display_order, :name), directory_query: query,
      featured_entries: Entry.strict_loading.visible.featured.with_directory_includes.limit(6),
      entries: query.call.page(params[:page]).per(12)
    }
  end

  def show
    entry = Entry.visible.with_resource_includes.find_by!(slug: params[:slug] || params[:id])
    recommendations = ResourceRecommendations.new(entry)
    render :show, locals: { entry: entry, author_resources: recommendations.by_author, related_resources: recommendations.by_topic }
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  end
end
