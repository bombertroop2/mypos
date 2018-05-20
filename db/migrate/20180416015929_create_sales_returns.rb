class CreateSalesReturns < ActiveRecord::Migration[5.0]
  def change
    create_table :sales_returns do |t|
      t.references :sale, foreign_key: true
      t.decimal :total_return
      t.integer :total_return_quantity
      t.string :document_number, index: {unique: true}

      t.timestamps
    end
  end
end
