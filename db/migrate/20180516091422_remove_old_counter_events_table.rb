class RemoveOldCounterEventsTable < ActiveRecord::Migration[5.0]
  def change
  	drop_table :counter_events

  	create_table :counter_events do |t|
	    t.string   :code
	    t.string   :name
	    t.datetime :start_date_time
	    t.datetime :end_date_time
	    t.float    :first_plus_discount
	    t.float    :second_plus_discount
	    t.decimal  :cash_discount
	    t.decimal  :special_price
	    t.string   :counter_event_type
	    t.decimal  :minimum_purchase_amount
	    t.decimal  :discount_amount
	    t.boolean  :is_active,               default: true
	    t.float 	 :margin, :float
  		t.float 	 :participation, :float
	    t.timestamps
	  end

	  add_index :counter_events, :code, unique: true
  end
end
