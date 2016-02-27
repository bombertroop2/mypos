json.array!(@purchase_returns) do |purchase_return|
  json.extract! purchase_return, :id, :number, :vendor_id
  json.url purchase_return_url(purchase_return, format: :json)
end
