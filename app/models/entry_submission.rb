# frozen_string_literal: true

# Owns a community submission and persists its resource and associations atomically.
class EntrySubmission
  COMMON_FIELDS = %i[
    title url description image_url experience_level submitter_name submitter_email category_ids
  ].freeze
  PERMITTED_FIELDS = ((COMMON_FIELDS - [ :category_ids ]) + ResourceAttributes::FIELDS.values.flatten +
    %i[resource_type author_id price]).uniq.freeze

  attr_reader :entry

  def initialize(attributes)
    @attributes = attributes.to_h.symbolize_keys
    @entry = Entry.new(@attributes.slice(*COMMON_FIELDS).merge(status: :pending, published: false))
  end

  def save
    return false unless valid_category_count?

    saved = persist_entry
    send_notifications if saved
    !!saved
  end

  private

  attr_reader :attributes

  def valid_category_count?
    return true if attributes[:category_ids].to_a.count(&:present?) <= 3

    entry.errors.add(:categories, "You can select a maximum of 3 categories")
    false
  end

  def persist_entry
    Entry.transaction do
      entry.entryable = ResourceAttributes.new(attributes).build
      raise ActiveRecord::Rollback unless entry.save

      associate_author
      true
    end
  end

  def associate_author
    author_id = attributes[:author_id]
    return if author_id.blank?

    author = Author.find_by(id: author_id)
    entry.authors << author if author
  end

  def send_notifications
    ActiveRecord.after_all_transactions_commit do
      ResourceSubmissionMailer.notify_team(entry).deliver_later
      ResourceSubmissionMailer.confirm_submitter(entry).deliver_later
    end
  end
end
