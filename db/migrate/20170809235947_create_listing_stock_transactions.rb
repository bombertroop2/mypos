class CreateListingStockTransactions < ActiveRecord::Migration[5.0]
  def change
    create_table :listing_stock_transactions do |t|
      t.integer :listing_stock_product_detail_id
      t.date :transaction_date
      t.string :transaction_number
      t.string :transaction_type
      t.integer :transactionable_id
      t.string :transactionable_type
      t.integer :quantity

      t.timestamps
    end
    add_foreign_key :listing_stock_transactions, :listing_stock_product_details, column: :listing_stock_product_detail_id
    add_index :listing_stock_transactions, :listing_stock_product_detail_id, name: "index_lst_on_listing_stock_product_detail_id"
    add_index :listing_stock_transactions, [:transactionable_type, :transactionable_id], name: "index_lst_on_transactionable_type_and_transactionable_id"
    add_index :listing_stock_transactions, [:listing_stock_product_detail_id, :transactionable_type, :transactionable_id], unique: true, name: "index_lst_on_lspd_id_transactionable_type_transactionable_id"
  end
end
