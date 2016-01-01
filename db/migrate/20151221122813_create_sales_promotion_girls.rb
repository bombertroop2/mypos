class CreateSalesPromotionGirls < ActiveRecord::Migration
  def change
    create_table :sales_promotion_girls do |t|
      t.string :identifier
      t.string :name
      t.text :address
      t.string :phone
      t.string :province
      t.references :warehouse, index: true, foreign_key: true
      t.string :mobile_phone

      t.timestamps null: false
    end
  end
end
