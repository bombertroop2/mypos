json.array!(@goods_types) do |goods_type|
  json.extract! goods_type, :id
  json.url goods_type_url(goods_type, format: :json)
end
