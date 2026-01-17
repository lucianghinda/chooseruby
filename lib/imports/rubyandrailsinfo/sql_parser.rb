# frozen_string_literal: true

module Imports
  module Rubyandrailsinfo
    # Parses PostgreSQL SQL dump files in COPY format
    # Extracts table data from tab-delimited COPY statements
    class SqlParser
      def initialize(sql_file_path)
        @sql_file_path = sql_file_path
        @content = File.read(sql_file_path)
      end

      # Extract data for a specific table
      # Returns array of hashes: [{column_name: value, ...}, ...]
      def extract_table(table_name)
        copy_block = find_copy_block(table_name)
        return [] if copy_block.nil?

        columns = extract_column_names(copy_block)
        data_lines = extract_data_lines(copy_block)

        parse_data_lines(data_lines, columns)
      end

      private

      # Find the COPY block for a specific table
      def find_copy_block(table_name)
        # Match: COPY "public"."table_name" (...) FROM stdin;
        # Capture everything until the terminator \.
        pattern = /COPY "public"\."#{Regexp.escape(table_name)}" \([^)]+\) FROM stdin;.*?^\\\.$/m
        match = @content.match(pattern)
        match&.to_s
      end

      # Extract column names from COPY statement
      # Example: COPY "public"."authors" ("id", "name", "created_at") FROM stdin;
      def extract_column_names(copy_block)
        match = copy_block.match(/COPY "public"\."[^"]+" \(([^)]+)\) FROM stdin;/)
        return [] unless match

        # Extract column names, remove quotes, trim whitespace
        match[1].scan(/"([^"]+)"/).flatten
      end

      # Extract data lines between COPY statement and \.
      def extract_data_lines(copy_block)
        lines = copy_block.split("\n")

        # Find start (line after COPY statement)
        start_idx = lines.find_index { |line| line.match?(/FROM stdin;/) }
        return [] unless start_idx

        # Find end (line with \.)
        end_idx = lines.find_index { |line| line == '\.' }
        return [] unless end_idx

        # Extract data lines (between start and end)
        lines[(start_idx + 1)...end_idx]
      end

      # Parse data lines into array of hashes
      def parse_data_lines(data_lines, columns)
        data_lines.map do |line|
          values = parse_line(line)
          next nil if values.nil? || values.length != columns.length

          # Create hash mapping column names to values
          Hash[columns.zip(values)]
        end.compact
      end

      # Parse a single data line (tab-delimited)
      def parse_line(line)
        # Split by tabs (PostgreSQL COPY uses tabs as delimiters)
        values = line.split("\t")

        # Convert each value (handle escapes and nulls)
        values.map { |val| convert_value(val) }
      end

      # Convert a raw value from PostgreSQL COPY format
      def convert_value(raw_value)
        return nil if raw_value == '\N' # PostgreSQL NULL
        return nil if raw_value.nil?
        return "" if raw_value.empty?

        # Unescape PostgreSQL escapes
        raw_value.gsub('\\t', "\t")
          .gsub('\\n', "\n")
          .gsub('\\r', "\r")
          .gsub("\\\\", "\\")
      end
    end
  end
end
