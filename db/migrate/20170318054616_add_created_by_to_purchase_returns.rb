class AddCreatedByToPurchaseReturns < ActiveRecord::Migration[5.0]
  def change
    add_column :purchase_returns, :created_by, :integer
    add_index :purchase_returns, :created_by
  end
end
