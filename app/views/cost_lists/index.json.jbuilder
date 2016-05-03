json.array!(@cost_lists) do |cost_list|
  json.extract! cost_list, :id
  json.url cost_list_url(cost_list, format: :json)
end
