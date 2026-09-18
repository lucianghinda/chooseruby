# frozen_string_literal: true

module Imports
  module Rubyandrailsinfo
    # Value conversions shared by PostgreSQL seed scripts and YAML imports.
    module Values
      module_function

      def decode_copy(value)
        return nil if value == '\N'

        value.gsub('\\t', "\t").gsub('\\n', "\n").gsub('\\r', "\r").gsub("\\\\", "\\")
      end

      def parse_time(value)
        return nil if value.blank? || value == '\N'

        Time.zone.parse(value)
      rescue ArgumentError
        nil
      end

      def parse_timestamp(value)
        return nil if value.blank?

        Time.parse(value)
      rescue ArgumentError, TypeError
        nil
      end

      def parse_bool(value)
        %w[ t true ].include?(value.to_s)
      end

      def to_int(value)
        return nil if value.blank? || value == '\N'

        value.to_i
      end
    end
  end
end
