class CreateCounterEventGeneralProducts < ActiveRecord::Migration[5.0]
  def change
  	# drop_table "counter_event_general_products"
    create_table :counter_event_general_products do |t|
	    t.integer  :counter_event_id
	    t.integer  :product_id
	    t.timestamps		  
	  end
		
  end
end
