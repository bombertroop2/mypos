json.array!(@counter_events) do |counter_event|
  json.extract! counter_event, :id
  json.url counter_event_url(counter_event, format: :json)
end
