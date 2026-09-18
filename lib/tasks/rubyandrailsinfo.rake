# frozen_string_literal: true

namespace :rubyandrailsinfo do
  desc "Convert PostgreSQL SQL dump to YAML files"
  task sql_to_yaml: :environment do
    converter = Imports::Rubyandrailsinfo::SqlToYamlConverter.new(
      sql_file: Rails.root.join("tmp/latest.sql"),
      output_dir: Rails.root.join("data/rubyandrailsinfo")
    )

    converter.convert_all
  end

  desc "Import YAML files into database (idempotent)"
  task yaml_to_db: :environment do
    importer = Imports::Rubyandrailsinfo::YamlImporter.new(
      yaml_dir: Rails.root.join("data/rubyandrailsinfo")
    )

    importer.import_all
  end
end
