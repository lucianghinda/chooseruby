# frozen_string_literal: true

module Imports
  module Rubyandrailsinfo
    # Writes normalized YAML tables from a PostgreSQL dump for review and import.
    class SqlToYamlConverter
      TABLES = %w[ tags authors books courses newsletters podcasts communities youtubes screencasts lessons authorings taggings ].freeze

      def initialize(sql_file:, output_dir:)
        @output_dir = output_dir
        @parser = SqlParser.new(sql_file)
      end

      def convert_all
        FileUtils.mkdir_p(@output_dir)
        puts "Converting SQL data to YAML files...\nOutput directory: #{@output_dir}\n\n"
        TABLES.each { |table_name| convert_table(table_name) }
        puts "\nAll conversions complete! YAML files created in #{@output_dir}"
      end

      private

      def convert_table(table_name)
        records = @parser.extract_table(table_name)
        data = records.map { |record| ConvertedRecord.new(table_name, record).attributes }
        write_yaml(table_name, data)
      end

      def write_yaml(table_name, data)
        filename = "#{table_name}.yml"
        File.write(File.join(@output_dir, filename), data.to_yaml)
        puts "✓ Converted #{table_name}: #{data.count} records → #{filename}"
      end
    end
  end
end
