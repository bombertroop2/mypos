class CreateStockMutationProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :stock_mutation_products do |t|
      t.references :stock_mutation, foreign_key: true
      t.references :product, foreign_key: true
      t.integer :quantity

      t.timestamps
    end
    add_index :stock_mutation_products, [:stock_mutation_id, :product_id], unique: true
  end
end
