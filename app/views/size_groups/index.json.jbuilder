json.array!(@size_groups) do |size_group|
  json.extract! size_group, :id, :code, :description
  json.url size_group_url(size_group, format: :json)
end
