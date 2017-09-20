class EventProductBrand < ApplicationRecord
  belongs_to :event
  belongs_to :brand
end
