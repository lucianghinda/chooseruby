# frozen_string_literal: true

class CategoriesController < ApplicationController
  before_action :load_category, only: :show

  def index
    @categories = Category.order(:display_order, :name)
  end

  def show
    @categories = Category.order(:display_order, :name)
    query_params = params.permit(:q, :level).to_h.merge(category: @category.slug)
    @directory_query = EntryDirectoryQuery.new(query_params)
    @query = @directory_query.query
    @active_level = @directory_query.level
    @entries = @directory_query.call.page(params[:page]).per(12)
  end

  private

  def load_category
    @category = Category.find_by!(slug: params[:slug])
  end
end
