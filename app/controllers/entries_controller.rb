# frozen_string_literal: true

# Searches resources and accepts public submissions for review.
class EntriesController < ApplicationController
  before_action :load_form_data, only: %i[new create]

  def index
    render_directory(:index)
  end

  def start
    render_directory(:start, level: params[:level].presence || "beginner")
  end

  def suggestions
    suggestions = EntrySuggestions.new(params[:q])
    return head :ok unless suggestions.searchable?

    render partial: "entries/suggestions", locals: { suggestions: }
  end

  def new
    @entry = Entry.new
  end

  def create
    submission = EntrySubmission.new(submission_params)
    @entry = submission.entry

    if submission.save
      redirect_to entry_success_path
    else
      flash.now[:alert] = "Please review the highlighted fields."
      render :new, status: :unprocessable_entity
    end
  end

  def success
  end

  private

  def render_directory(template, overrides = {})
    filters = params.permit(:q, :level, :category, :sort).to_h.merge(overrides)
    directory = EntryDirectoryQuery.new(filters)
    entries = directory.call.page(params[:page]).per(25)
    render template, locals: { directory:, entries: }
  end

  def load_form_data
    @categories = Category.order(:name)
    @authors = Author.approved.order(:name)
  end

  def submission_params
    params.require(:entry).permit(*EntrySubmission::PERMITTED_FIELDS, category_ids: [])
  end
end
