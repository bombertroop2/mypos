class AddUniqueIndexOnCodeToCounterEvents < ActiveRecord::Migration[5.0]
  def change
    add_index :counter_events, :code, unique: true
  end
end
