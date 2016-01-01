json.array!(@warehouses) do |warehouse|
  json.extract! warehouse, :id, :code, :name, :address, :is_active, :supervisor_id, :region_id, :warehouse_type
  json.url warehouse_url(warehouse, format: :json)
end
