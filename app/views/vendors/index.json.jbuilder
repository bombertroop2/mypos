json.array!(@vendors) do |vendor|
  json.extract! vendor, :id, :code, :name, :phone, :facsimile, :email, :pic_name, :pic_phone, :pic_mobile_phone, :pic_email, :address
  json.url vendor_url(vendor, format: :json)
end
