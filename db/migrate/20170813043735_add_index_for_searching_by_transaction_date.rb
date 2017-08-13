class AddIndexForSearchingByTransactionDate < ActiveRecord::Migration[5.0]
  def change
    add_index :listing_stock_transactions, [:listing_stock_product_detail_id, :transaction_date], name: "index_lst_on_lspd_id_and_transaction_date"
  end
end
