class ChangeMarginAndParticipationFieldToFloat < ActiveRecord::Migration[5.0]
  def change
  	change_column :counter_events, :margin, :float
  	change_column :counter_events, :participation, :float  	
  end
end
