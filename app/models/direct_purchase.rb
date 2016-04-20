class DirectPurchase < ActiveRecord::Base
  belongs_to :vendor
  belongs_to :warehouse
end
