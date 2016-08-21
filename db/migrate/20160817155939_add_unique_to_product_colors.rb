class AddUniqueToProductColors < ActiveRecord::Migration[5.0]
  def change
    add_index :product_colors, [:product_id, :color_id], :unique => true
  end
end
