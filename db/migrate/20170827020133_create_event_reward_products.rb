class CreateEventRewardProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :event_reward_products do |t|
      t.references :event, foreign_key: true
      t.references :product, foreign_key: true

      t.timestamps
    end
  end
end
