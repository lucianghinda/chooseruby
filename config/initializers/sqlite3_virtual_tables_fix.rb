# frozen_string_literal: true

# Workaround for Rails bug: SQLite3 adapter's virtual_tables regex
# uses . which doesn't match \n, failing on multi-line CREATE VIRTUAL TABLE SQL.
# Remove once fixed upstream.

ActiveSupport.on_load(:active_record_sqlite3adapter) do
  ActiveRecord::ConnectionAdapters::SQLite3Adapter.prepend(Module.new do
    def virtual_tables
      query = <<~SQL
        SELECT name, sql FROM sqlite_master WHERE sql LIKE 'CREATE VIRTUAL %';
      SQL

      query_rows(query).each_with_object({}) do |(table_name, sql), memo|
        normalized_sql = sql.gsub(/\s+/, " ").strip
        match = normalized_sql.match(/USING\s+(\w+)\s*\((.+)\)/i)
        next unless match

        _, module_name, arguments = match.to_a
        memo[table_name] = [ module_name, arguments ]
      end.to_a
    end
  end)
end
