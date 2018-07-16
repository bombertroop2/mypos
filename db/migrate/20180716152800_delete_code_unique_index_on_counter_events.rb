class DeleteCodeUniqueIndexOnCounterEvents < ActiveRecord::Migration[5.0]
  def change
    remove_index :counter_events, :code
  end
end
