class CreateSalesReturnProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :sales_return_products do |t|
      t.references :sale_product, foreign_key: true

      t.timestamps
    end
  end
end
