class EventRewardProduct < ApplicationRecord
  belongs_to :event
  belongs_to :product
end
