# frozen_string_literal: true

# Finds the first available numbered slug without treating the record as a conflict.
class UniqueSlug
  def initialize(record, text)
    @record = record
    @base_slug = text.parameterize
  end

  def to_s
    return base_slug unless taken?(base_slug)

    suffix = 1
    suffix += 1 while taken?("#{base_slug}-#{suffix}")
    "#{base_slug}-#{suffix}"
  end

  private

  attr_reader :record, :base_slug

  def taken?(candidate)
    record.class.where(slug: candidate).where.not(id: record.id).exists?
  end
end
