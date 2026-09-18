# frozen_string_literal: true

module Imports
  module Rubyandrailsinfo
    # Helper methods for importing data from PostgreSQL dump
    # Provides ID mapping for polymorphic associations and data conversion utilities
    class Helpers
      def initialize
        @id_mapper = IdMapper.new
      end

      # Evaluate each trusted seed in the same import instance so relationships
      # share mappings without exposing state or helper methods to other imports.
      def load_seed(path)
        instance_eval(File.read(path), path.to_s)
      end

      delegate :register_entry, :find_entry, :register_author, :find_author,
        :register_category, :find_category, to: :@id_mapper

      # Progress output helper

      def progress(current, total, label)
        print "\r  #{label}: #{current}/#{total}"
        puts "" if current == total
      end

      # Reset the mappings before reusing an import context.

      def reset_lookups
        @id_mapper = IdMapper.new
      end
      alias_method :reset_lookups!, :reset_lookups
    end
  end
end
