class EventGeneralProduct < ApplicationRecord
  belongs_to :event
  belongs_to :product

  attr_accessor :prdct_code, :prdct_name
end
