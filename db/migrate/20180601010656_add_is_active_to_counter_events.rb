class AddIsActiveToCounterEvents < ActiveRecord::Migration[5.0]
  def change
    add_column :counter_events, :is_active, :boolean, default: true
  end
end
