# frozen_string_literal: true

class Avo::Resources::Book < Avo::BaseResource
  self.title = :display_name
  self.includes = [ :entry ]
  self.description = "Create a Book first, then create an Entry and select this Book as the entryable"

  def fields
    field :id, as: :id, link_to_record: true

    # Book-specific information
    field :isbn, as: :text, help: "ISBN number (optional)"
    field :publisher, as: :text, help: "Publisher name"
    field :publication_year, as: :number, help: "Year of publication (1990-present)"
    field :page_count, as: :number, help: "Number of pages"
    field :format, as: :select,
          enum: ::Book.formats,
          help: "Book format"
    field :purchase_url, as: :text, help: "Where to buy this book"

    # Association to base entry resource
    field :entry, as: :has_one,
          help: "After creating this Book, go to Entries → New and select this Book"

    # Timestamps
    field :created_at, as: :date_time, readonly: true, hide_on: [ :index ]
    field :updated_at, as: :date_time, readonly: true, hide_on: [ :index ]
  end
end
