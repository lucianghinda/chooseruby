# frozen_string_literal: true

# Abstract base class all models inherit from.
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
