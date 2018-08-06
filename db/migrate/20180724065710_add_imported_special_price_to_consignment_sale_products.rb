class AddImportedSpecialPriceToConsignmentSaleProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :consignment_sale_products, :imported_special_price, :decimal, default: nil
  end
end
