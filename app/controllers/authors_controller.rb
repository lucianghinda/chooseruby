# frozen_string_literal: true

class AuthorsController < ApplicationController
  def index
    # Initialize search query with permitted params
    permitted_params = params.permit(:q, :page).to_h
    @query_object = AuthorSearchQuery.new(permitted_params)
    @query = @query_object.query

    # Paginate results: 25 per page
    @authors = @query_object.call.page(params[:page]).per(25)
  end

  def show
    # Find author by slug, only show approved authors
    @author = Author.approved.find_by!(slug: params[:slug])

    # Eager load resources to avoid N+1 queries and paginate
    @entries = @author.entries.page(params[:page]).per(20)
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  end

  # API endpoint for author autocomplete search
  # Returns JSON array of approved authors matching the query
  def search
    query = params[:q].to_s.strip

    # Return empty results if query is blank
    if query.blank?
      render json: []
      return
    end

    # Use AuthorSearchQuery to search with FTS5
    search_results = AuthorSearchQuery.new({ q: query }).call

    # Limit to 10 results for autocomplete
    authors = search_results.limit(10)

    # Return JSON with id, name, and github_url
    render json: authors.map { |author|
      {
        id: author.id,
        name: author.name,
        github_url: author.github_url
      }
    }
  end
end
