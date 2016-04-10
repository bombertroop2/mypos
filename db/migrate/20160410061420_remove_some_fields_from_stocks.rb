class RemoveSomeFieldsFromStocks < ActiveRecord::Migration
  def change
    remove_reference :stocks, :purchase_order_detail, index: true, foreign_key: true
    remove_column :stocks, :stock_type, :string
    remove_column :stocks, :quantity_on_hand, :integer
  end
end
