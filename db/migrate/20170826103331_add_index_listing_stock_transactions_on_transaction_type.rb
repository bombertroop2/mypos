class AddIndexListingStockTransactionsOnTransactionType < ActiveRecord::Migration[5.0]
  def change
    add_index :listing_stock_transactions, :transaction_type
  end
end
