class AddSomeFieldsToPurchaseOrderDetails < ActiveRecord::Migration
  def change
    add_reference :purchase_order_details, :size, index: true
    add_reference :purchase_order_details, :color, index: true
    add_foreign_key :purchase_order_details, :common_fields, column: :color_id
  end
end
