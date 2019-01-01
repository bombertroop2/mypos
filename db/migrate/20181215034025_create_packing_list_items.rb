class CreatePackingListItems < ActiveRecord::Migration[5.0]
  def change
    create_table :packing_list_items do |t|
      t.references :shipment, foreign_key: true
      t.float :volume
      t.float :weight
      t.references :packing_list, foreign_key: true, index: false
      t.integer :quantity

      t.timestamps
    end
    add_index :packing_list_items, [:packing_list_id, :shipment_id], unique: true
  end
end
