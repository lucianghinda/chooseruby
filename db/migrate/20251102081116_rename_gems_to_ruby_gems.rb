# frozen_string_literal: true

class RenameGemsToRubyGems < ActiveRecord::Migration[8.1]
  def change
    rename_table :gems, :ruby_gems
  end
end
