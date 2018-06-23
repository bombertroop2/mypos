class AddNoSaleToConsignmentSales < ActiveRecord::Migration[5.0]
  def change
    add_column :consignment_sales, :no_sale, :boolean, default: false
  end
end
