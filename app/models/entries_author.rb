# frozen_string_literal: true

# Join table model for many-to-many relationship between Entries and Authors
#
# This model represents the association table that connects entries to authors,
# allowing each entry to have multiple authors and each author to have
# multiple entries.
#
# Associations:
#   - belongs_to :entry
#   - belongs_to :author
#
# Usage:
#   entry = Entry.find_by(title: "RSpec")
#   author = Author.find_by(name: "David Chelimsky")
#   EntriesAuthor.create(entry: entry, author: author)
#
# == Schema Information
#
# Table name: entries_authors
# Database name: primary
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  author_id  :integer          not null
#  entry_id   :integer          not null
#
# Indexes
#
#  index_entries_authors_on_author_id               (author_id)
#  index_entries_authors_on_author_id_and_entry_id  (author_id,entry_id) UNIQUE
#  index_entries_authors_on_entry_id                (entry_id)
#
# Foreign Keys
#
#  author_id  (author_id => authors.id) ON DELETE => cascade
#  entry_id   (entry_id => entries.id) ON DELETE => cascade
#
class EntriesAuthor < ApplicationRecord
  belongs_to :entry
  belongs_to :author
end
