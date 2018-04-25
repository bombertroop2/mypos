class AddMarginAndParticipationToCounterEvents < ActiveRecord::Migration[5.0]
  def change
  	add_column :counter_events, :margin, :float
  	add_column :counter_events, :participation, :float
  end
end
