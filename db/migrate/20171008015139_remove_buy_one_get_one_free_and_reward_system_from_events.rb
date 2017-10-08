class RemoveBuyOneGetOneFreeAndRewardSystemFromEvents < ActiveRecord::Migration[5.0]
  def change
    remove_column :events, :buy_one_get_one_free, :boolean
    remove_column :events, :reward_system, :boolean
  end
end
