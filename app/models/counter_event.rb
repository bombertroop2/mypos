class CounterEvent < ApplicationRecord
	validates :code, :name, :start_time, :end_time, presence: true

	has_many :counter_event_warehouses
	
	def set_warehouses(w_ids)
		puts "w_ids #{w_ids}"
		counter_event_warehouses.destroy_all
		warehouse_ids = w_ids.split(", ")
		arr = warehouse_ids.map {|x| {counter_event_id: id, warehouse_id: x}}
		p arr
		CounterEventWarehouse.create(arr)
	end
end
