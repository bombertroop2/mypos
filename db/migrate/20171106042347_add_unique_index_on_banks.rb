class AddUniqueIndexOnBanks < ActiveRecord::Migration[5.0]
  def change
    add_index :banks, [:code, :card_type], unique: true
  end
end
