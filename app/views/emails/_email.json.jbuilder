json.extract! email, :id, :address, :type, :created_at, :updated_at
json.url email_url(email, format: :json)