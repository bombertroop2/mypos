class AddReadToRecipients < ActiveRecord::Migration[5.0]
  def change
    add_column :recipients, :read, :boolean, default: false
  end
end
