class AddActivityColumnToJournal < ActiveRecord::Migration[5.0]
  def change
    add_column :journals, :activity, :string
    add_reference :journals, :warehouse, index: true
  end
end
