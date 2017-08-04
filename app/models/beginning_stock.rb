class BeginningStock < ApplicationRecord
  belongs_to :warehouse
  has_many :beginning_stock_months, dependent: :destroy
end
