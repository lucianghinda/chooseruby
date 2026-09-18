# frozen_string_literal: true

module Imports
  module Rubyandrailsinfo
    # Imports normalized YAML in dependency order using one ID map per import run.
    class YamlImporter
      TABLES = %w[ tags authors books courses newsletters podcasts communities youtubes screencasts lessons authorings taggings ].freeze

      def initialize(yaml_dir:)
        @yaml_dir = yaml_dir
        @id_mapper = IdMapper.new
        @results = []
      end

      def import_all
        puts "Importing YAML data from #{@yaml_dir}...\n\n"
        TABLES.each { |table| import_table(table) }
        print_summary
      end

      private

      def import_table(table)
        @results << ImportBatch.new(table, @yaml_dir, @id_mapper).run
      end

      def print_summary
        separator = "=" * 60
        puts "\n#{separator}\nImport Summary\n#{separator}"
        @results.each(&:print_summary)
        puts "\nID Mappings: #{@id_mapper.stats.inspect}"
      end
    end
  end
end
