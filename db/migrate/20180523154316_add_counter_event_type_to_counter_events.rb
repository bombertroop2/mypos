class AddCounterEventTypeToCounterEvents < ActiveRecord::Migration[5.0]
  def change
  	add_column :counter_events, :counter_event_type, :string
  end
end
