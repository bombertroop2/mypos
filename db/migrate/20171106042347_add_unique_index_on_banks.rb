class AddUniqueIndexOnBanks < ActiveRecord::Migration[5.0]
  def change
    add_index :banks, :code, unique: true
  end
end
