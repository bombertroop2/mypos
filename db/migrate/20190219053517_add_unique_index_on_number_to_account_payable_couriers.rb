class AddUniqueIndexOnNumberToAccountPayableCouriers < ActiveRecord::Migration[5.0]
  def change
    add_index :account_payable_couriers, :number, unique: true
  end
end
