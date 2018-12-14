class AddNoteToAccountPayables < ActiveRecord::Migration[5.0]
  def change
    add_column :account_payables, :note, :text
  end
end
