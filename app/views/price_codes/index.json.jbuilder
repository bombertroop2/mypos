json.array!(@price_codes) do |price_code|
  json.extract! price_code, :id, :code, :name, :description
  json.url price_code_url(price_code, format: :json)
end
