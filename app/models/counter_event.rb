class CounterEvent < ApplicationRecord
	validates :code, :name, :start_time, :end_time, presence: true
	validates :start_time, date: {after_or_equal_to: proc {Time.current}, message: 'must be after or equal to current time' }, if: proc{|evnt| evnt.start_time.present? && evnt.start_time_changed?}
  validates :end_time, date: {after: proc {|evnt| evnt.start_time}, message: 'must be after start time' }, if: proc{|evnt| evnt.start_time.present? && evnt.end_time.present?}
  validates :special_price, presence: true, if: proc{|event| event.special_price.present? }
  validates :first_discount, presence: true, if: proc{|event| !event.special_price.present? }
  
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
