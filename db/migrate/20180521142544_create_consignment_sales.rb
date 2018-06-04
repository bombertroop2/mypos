class CreateConsignmentSales < ActiveRecord::Migration[5.0]
  def change
    create_table :consignment_sales do |t|
      t.date :transaction_date
      t.boolean :approved, default: false
      t.string :transaction_number
      t.decimal :total

      t.timestamps
    end
    add_index :consignment_sales, :transaction_number, unique: true
  end
end
