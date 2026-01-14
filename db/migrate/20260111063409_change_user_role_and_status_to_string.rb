# frozen_string_literal: true

class ChangeUserRoleAndStatusToString < ActiveRecord::Migration[8.1]
  def up
    # Add temporary columns for string values
    add_column :users, :role_string, :string
    add_column :users, :status_string, :string

    # Convert existing integer values to strings
    # role: { editor: 0, admin: 1 }
    execute <<~SQL
      UPDATE users SET role_string = CASE
        WHEN role = 0 THEN 'editor'
        WHEN role = 1 THEN 'admin'
        ELSE 'editor'
      END
    SQL

    # status: { active: 0, suspended: 1 }
    execute <<~SQL
      UPDATE users SET status_string = CASE
        WHEN status = 0 THEN 'active'
        WHEN status = 1 THEN 'suspended'
        ELSE 'active'
      END
    SQL

    # Remove old integer columns
    remove_column :users, :role
    remove_column :users, :status

    # Rename string columns to final names
    rename_column :users, :role_string, :role
    rename_column :users, :status_string, :status

    # Add default and null constraints
    change_column_default :users, :role, "editor"
    change_column_null :users, :role, false

    change_column_default :users, :status, "active"
    change_column_null :users, :status, false
  end

  def down
    # Add temporary integer columns
    add_column :users, :role_integer, :integer
    add_column :users, :status_integer, :integer

    # Convert string values back to integers
    execute <<~SQL
      UPDATE users SET role_integer = CASE
        WHEN role = 'editor' THEN 0
        WHEN role = 'admin' THEN 1
        ELSE 0
      END
    SQL

    execute <<~SQL
      UPDATE users SET status_integer = CASE
        WHEN status = 'active' THEN 0
        WHEN status = 'suspended' THEN 1
        ELSE 0
      END
    SQL

    # Remove string columns
    remove_column :users, :role
    remove_column :users, :status

    # Rename integer columns to final names
    rename_column :users, :role_integer, :role
    rename_column :users, :status_integer, :status

    # Add default and null constraints
    change_column_default :users, :role, 0
    change_column_null :users, :role, false

    change_column_default :users, :status, 0
    change_column_null :users, :status, false
  end
end
