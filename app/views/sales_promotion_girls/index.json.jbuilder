json.array!(@sales_promotion_girls) do |sales_promotion_girl|
  json.extract! sales_promotion_girl, :id, :identifier, :name, :address, :phone, :province, :warehouse_id, :mobile_phone
  json.url sales_promotion_girl_url(sales_promotion_girl, format: :json)
end
