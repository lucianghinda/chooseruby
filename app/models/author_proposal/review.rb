# frozen_string_literal: true

# Applies approved author changes atomically and records rejection feedback.
module AuthorProposal::Review
  def approve!
    transaction { apply_approval }
    true
  end

  def reject!(admin_comment:)
    raise ArgumentError, "admin_comment is required for rejection" if admin_comment.blank?

    update!(
      status: :rejected,
      admin_comment: admin_comment,
      reviewed_at: Time.current,
      reviewer_id: nil  # Will be populated when admin system exists
    )

    # Send rejection email
    send_rejection_email

    true
  end

  private

  def apply_approval
    target_author = reviewed_author
    update_author(target_author)
    associate_author(target_author)
    update!(status: :approved, reviewed_at: Time.current, reviewer_id: nil)
    send_approval_email
  end

  def reviewed_author
    author_id.present? ? Author.find(author_id) : Author.new(name: author_name)
  end

  def update_author(target_author)
    target_author.bio = bio_text if bio_text.present?
    apply_link_updates_to_author(target_author) if link_updates.present?
    target_author.save!
  end

  def associate_author(target_author)
    self.author_id = target_author.id if author_id.blank?
    create_entries_author_association(target_author) if matched_entry_id.present?
  end

  def apply_link_updates_to_author(target_author)
    link_updates.each do |field_name, url_value|
      next if url_value.blank?

      # Validate field exists on Author model
      unless target_author.has_attribute?(field_name)
        raise ArgumentError, "Invalid link field: #{field_name}"
      end

      target_author.public_send("#{field_name}=", url_value)
    end
  end

  def create_entries_author_association(target_author)
    return if EntriesAuthor.exists?(author: target_author, entry_id: matched_entry_id)

    EntriesAuthor.create!(
      author: target_author,
      entry_id: matched_entry_id
    )
  end
end
