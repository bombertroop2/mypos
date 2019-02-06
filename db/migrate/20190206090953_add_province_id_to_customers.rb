class AddProvinceIdToCustomers < ActiveRecord::Migration[5.0]
  def change
    add_reference :customers, :province, foreign_key: true
  end
end
