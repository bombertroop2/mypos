class AddEventIdToSaleProducts < ActiveRecord::Migration[5.0]
  def change
    add_reference :sale_products, :event, foreign_key: true
  end
end
