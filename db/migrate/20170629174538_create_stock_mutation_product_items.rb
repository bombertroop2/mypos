class CreateStockMutationProductItems < ActiveRecord::Migration[5.0]
  def change
    create_table :stock_mutation_product_items do |t|
      t.references :stock_mutation_product, foreign_key: true, index: {name: "index_smpi_on_stock_mutation_product_id"}
      t.references :size, foreign_key: true
      t.references :color, index: true
      t.integer :quantity

      t.timestamps
    end
    add_foreign_key :stock_mutation_product_items, :common_fields, column: :color_id
    add_index :stock_mutation_product_items, [:stock_mutation_product_id, :size_id, :color_id], unique: true, name: "index_smpi_on_stock_mutation_product_id_size_id_color_id"
  end
end
