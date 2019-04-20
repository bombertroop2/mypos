class CreateIncentives < ActiveRecord::Migration[5.0]
  def change
    create_table :incentives do |t|
      t.string :warehouse_code
      t.string :warehouse_name
      t.date :transaction_date
      t.string :sales_promotion_girl_identifier
      t.string :sales_promotion_girl_name
      t.string :transaction_number
      t.decimal :net_sales
      t.decimal :incentive
      t.integer :quantity

      t.timestamps
    end
  end
end
