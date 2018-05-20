class AddReturnedProductIdToSaleProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :sale_products, :returned_product_id, :integer
    add_index :sale_products, :returned_product_id, unique: true
  end
end
