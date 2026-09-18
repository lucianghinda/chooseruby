# frozen_string_literal: true

module Imports
  module Rubyandrailsinfo
    # Helper methods for importing data from PostgreSQL dump
    # Provides ID mapping for polymorphic associations and data conversion utilities
    module Helpers
      class << self
        # Data conversion helpers

        def parse_time(str)
          return nil if str.nil? || str == '\N' || str.empty?
          Time.zone.parse(str)
        rescue ArgumentError
          nil
        end

        def parse_bool(str)
          str == "t" || str == "true"
        end

        def to_int(str)
          return nil if str.nil? || str == '\N' || str.empty?
          str.to_i
        end

        # Progress output helper

        def progress(current, total, label)
          print "\r  #{label}: #{current}/#{total}"
          puts "" if current == total
        end
      end
    end
  end
end
