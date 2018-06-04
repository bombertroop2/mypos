class AddCounterEventIdToConsignmentSales < ActiveRecord::Migration[5.0]
  def change
    add_reference :consignment_sales, :counter_event, foreign_key: true
  end
end
