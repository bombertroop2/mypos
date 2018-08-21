class AddDescriptionToCoaTypes < ActiveRecord::Migration[5.0]
  def change
    add_column :coa_types, :description, :text
  end
end
