json.array!(@purchase_orders) do |purchase_order|
  json.extract! purchase_order, :id, :number, :po_type, :status, :vendor_id, :request_delivery_date, :order_value, :receiving_value, :means_of_payment, :warehouse_id
  json.url purchase_order_url(purchase_order, format: :json)
end
