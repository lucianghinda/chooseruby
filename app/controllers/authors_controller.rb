# frozen_string_literal: true

# Browses approved authors and provides author autocomplete results.
class AuthorsController < ApplicationController
  def index
    query = AuthorSearchQuery.new(params.permit(:q, :page).to_h)
    render :index, locals: { query_object: query, authors: query.call.page(params[:page]).per(25) }
  end

  def show
    author = Author.strict_loading.approved.with_attached_avatar.find_by!(slug: params[:slug])
    entries = author.entries.strict_loading.with_rich_text_description.page(params[:page]).per(20)
    render :show, locals: { author: author, entries: entries }
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  end

  # Returns the first ten approved authors matching the autocomplete query.
  def search
    query = params[:q].to_s.strip
    return render json: [] if query.blank?

    authors = AuthorSearchQuery.new({ q: query }).call.limit(10)
    render json: authors.as_json(only: %i[ id name github_url ])
  end
end
