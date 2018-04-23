class CounterEventWarehouse < ApplicationRecord
	belongs_to :counter_event
	belongs_to :warehouse
end
