class AddCityIdToCustomers < ActiveRecord::Migration[5.0]
  def change
    add_reference :customers, :city, foreign_key: true
  end
end
