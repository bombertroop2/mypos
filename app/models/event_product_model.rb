class EventProductModel < ApplicationRecord
  belongs_to :event
  belongs_to :model
end
