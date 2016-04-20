class CreateDirectPurchases < ActiveRecord::Migration
  def change
    create_table :direct_purchases do |t|
      t.references :vendor, index: true, foreign_key: true
      t.references :warehouse, index: true, foreign_key: true
      t.float :first_discount
      t.float :second_discount
      t.decimal :price_discount
      t.boolean :is_additional_disc_from_net
      t.string :vat_type
      t.boolean :is_taxable_entrepreneur

      t.timestamps null: false
    end
  end
end
