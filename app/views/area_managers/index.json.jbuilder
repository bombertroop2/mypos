json.array!(@supervisors) do |supervisor|
  json.extract! supervisor, :id, :code, :name, :address, :email, :phone, :mobile_phone
  json.url supervisor_url(supervisor, format: :json)
end
