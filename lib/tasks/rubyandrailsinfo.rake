# frozen_string_literal: true

require_relative "../imports/rubyandrailsinfo/sql_parser"
require_relative "../imports/rubyandrailsinfo/sql_to_yaml_converter"
require_relative "../imports/rubyandrailsinfo/id_mapper"
require_relative "../imports/rubyandrailsinfo/yaml_importer"

namespace :rubyandrailsinfo do
  desc "Convert PostgreSQL SQL dump to YAML files"
  task sql_to_yaml: :environment do
    converter = Rubyandrailsinfo::SqlToYamlConverter.new(
      sql_file: Rails.root.join("tmp/latest.sql"),
      output_dir: Rails.root.join("data/rubyandrailsinfo")
    )

    converter.convert_all
  end

  desc "Import YAML files into database (idempotent)"
  task yaml_to_db: :environment do
    importer = Rubyandrailsinfo::YamlImporter.new(
      yaml_dir: Rails.root.join("data/rubyandrailsinfo")
    )

    importer.import_all
  end
end
