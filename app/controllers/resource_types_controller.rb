# frozen_string_literal: true

# Browses resources and category statistics for one supported resource type.
class ResourceTypesController < ApplicationController
  before_action :validate_type_parameter

  def show
    type = params[:type]
    query = EntryDirectoryQuery.new(params.permit(:q, :level, :category, :type).to_h.merge(type: type))
    directory = ResourceTypeDirectory.new(type)
    render :show, locals: {
      type: type, directory_query: query, categories: Category.strict_loading.order(:display_order, :name),
      featured_entries: directory.featured_entries, category_stats: directory.category_stats,
      entries: query.call.page(params[:page]).per(25)
    }
  end

  private

  def validate_type_parameter
    type = params[:type]
    unless Entry::VALID_TYPES.key?(type)
      raise ActiveRecord::RecordNotFound, "Invalid resource type: #{type}"
    end
  end
end
