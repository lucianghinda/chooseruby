# frozen_string_literal: true

module Imports
  module Rubyandrailsinfo
    # Accounts for each imported row and allows later rows to survive a bad record.
    class ImportBatch
      IMPORTERS = {
        "tags" => ImportedCatalogRecord,
        "authors" => ImportedCatalogRecord,
        "authorings" => ImportedAssociation,
        "taggings" => ImportedAssociation
      }.freeze

      def initialize(table, directory, mapper)
        @table = table
        @path = File.join(directory, "#{table}.yml")
        @mapper = mapper
        @result = ImportResult.new(table)
      end

      def run
        records.each { |record| import_record(record) }
        @result.print_progress
        @result
      end

      private

      def records
        YAML.load_file(@path) || []
      end

      def import_record(record)
        importer = IMPORTERS.fetch(@table, ImportedEntity).new(@table, record, @mapper)
        @result.record(importer.import)
      rescue StandardError => error
        puts "  ✗ Error importing #{@table.singularize} #{record['id']}: #{error.message}"
        @result.record(:errors)
      end
    end
  end
end
