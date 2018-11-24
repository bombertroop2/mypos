class AddNumberToAdjustments < ActiveRecord::Migration[5.0]
  def change
    add_column :adjustments, :number, :string
  end
end
