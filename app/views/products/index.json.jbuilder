json.array!(@products) do |product|
  json.extract! product, :id, :code, :description, :brand_id, :sex, :vendor_id, :target, :model_id, :goods_type_id, :image, :effective_date
  json.url product_url(product, format: :json)
end
