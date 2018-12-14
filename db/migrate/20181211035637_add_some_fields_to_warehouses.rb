class AddSomeFieldsToWarehouses < ActiveRecord::Migration[5.0]
  def change
    add_reference :warehouses, :province, foreign_key: true
    add_reference :warehouses, :city, foreign_key: true
  end
end
