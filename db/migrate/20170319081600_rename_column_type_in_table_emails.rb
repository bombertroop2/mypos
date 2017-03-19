class RenameColumnTypeInTableEmails < ActiveRecord::Migration[5.0]
  def change
    rename_column :emails, :type, :email_type
  end
end
