class AddSomeFieldsToEvents < ActiveRecord::Migration[5.0]
  def change
    add_column :events, :first_plus_discount, :float
    add_column :events, :second_plus_discount, :float
    add_column :events, :cash_discount, :decimal
    add_column :events, :special_price, :decimal
    add_column :events, :buy_one_get_one_free, :boolean, default: nil
    add_column :events, :reward_system, :boolean, default: nil
    add_column :events, :minimum_purchase_amount, :decimal
  end
end
