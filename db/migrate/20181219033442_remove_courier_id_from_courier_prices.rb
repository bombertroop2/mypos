class RemoveCourierIdFromCourierPrices < ActiveRecord::Migration[5.0]
  def change
    remove_reference :courier_prices, :courier, foreign_key: true
  end
end
