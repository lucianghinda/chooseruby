# frozen_string_literal: true

module Imports
  module Rubyandrailsinfo
    # Extracts complete PostgreSQL COPY blocks and decodes their tab-separated rows.
    class SqlParser
      def initialize(sql_file_path)
        @content = File.read(sql_file_path)
      end

      def extract_table(table_name)
        pattern = /COPY "public"\."#{Regexp.escape(table_name)}" \(([^)]+)\) FROM stdin;\r?\n(.*?)^\\\.$/m
        block = @content.match(pattern)
        return [] unless block

        CopyBlock.new(*block.captures).records
      end

      # A matched block has both a header and terminator, so no partial rows leak out.
      class CopyBlock
        def initialize(header, data)
          @columns = header.scan(/"([^"]+)"/).flatten
          @lines = data.lines(chomp: true)
        end

        def records
          @lines.filter_map { |line| CopyRow.new(@columns, line).attributes }
        end
      end

      # Keeps empty trailing columns while rejecting rows with mismatched field counts.
      class CopyRow
        def initialize(columns, line)
          @columns = columns
          @values = line.split("\t", -1).map { |value| Values.decode_copy(value) }
        end

        def attributes
          return unless @columns.length == @values.length

          @columns.zip(@values).to_h
        end
      end
    end
  end
end
