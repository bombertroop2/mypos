class City < ApplicationRecord
  belongs_to :province
  has_many :courier_prices
end
