json.array!(@price_lists) do |price_list|
  json.extract! price_list, :id, :effective_date, :price, :product_detail_id
  json.url price_list_url(price_list, format: :json)
end
