class EventProduct < ApplicationRecord
  attr_accessor :prdct_code, :prdct_name
  
  belongs_to :event_warehouse
  belongs_to :product
  
  validates :product_id, presence: true
end
