# frozen_string_literal: true

module Imports
  module Rubyandrailsinfo
    # Counts row outcomes and renders progress and the final summary consistently.
    class ImportResult
      def initialize(table)
        @name = table == "tags" ? "categories" : table
        @counts = { success: 0, errors: 0, skipped: 0 }
      end

      def record(outcome)
        @counts[outcome] += 1
      end

      def print_progress
        puts "✓ Imported #{@counts[:success]} #{@name} (#{@counts[:errors]} errors, #{@counts[:skipped]} skipped)"
      end

      def print_summary
        puts "#{@name.capitalize}: #{@counts[:success]} success"
        @counts.except(:success).each { |name, count| print_count(name, count) }
      end

      private

      def print_count(name, count)
        puts "  #{name.to_s.capitalize}: #{count}" if count.positive?
      end
    end
  end
end
