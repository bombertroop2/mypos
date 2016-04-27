class AddReceivingDateToDirectPurchases < ActiveRecord::Migration
  def change
    add_column :direct_purchases, :receiving_date, :date
  end
end
