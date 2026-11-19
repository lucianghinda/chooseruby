# frozen_string_literal: true

# Base class for persistent application records.
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
