class EventProductGoodsType < ApplicationRecord
  belongs_to :event
  belongs_to :goods_type
end
