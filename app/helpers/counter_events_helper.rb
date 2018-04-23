module CounterEventsHelper
	def event_warehouses
		event_warehouses = if action_name.eql?("edit") 
  		@counter_event.counter_event_warehouses.select(:id, :warehouse_id, :code, :name, :select_different_products).joins(:warehouse) 
 		elsif action_name.eql?("update") 
 			@counter_event.event_warehouses 
 		elsif !@counter_event.new_record? 
			@event_warehouses 
		else 
 			@counter_event.counter_event_warehouses 
		end
	end
end
