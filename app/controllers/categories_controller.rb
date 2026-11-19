# frozen_string_literal: true

# Browses resource categories and the resources assigned to each.
class CategoriesController < ApplicationController
  def index
    render :index, locals: { categories: Category.strict_loading.order(:display_order, :name) }
  end

  def show
    category = Category.strict_loading.find_by!(slug: params[:slug])
    query_params = params.permit(:q, :level).to_h.merge(category: category.slug)
    query = EntryDirectoryQuery.new(query_params)
    render :show, locals: { category: category, directory_query: query, entries: query.call.page(params[:page]).per(12) }
  end
end
