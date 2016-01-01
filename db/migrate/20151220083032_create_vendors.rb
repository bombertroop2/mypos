class CreateVendors < ActiveRecord::Migration
  def change
    create_table :vendors do |t|
      t.string :code
      t.string :name
      t.string :phone
      t.string :facsimile
      t.string :email
      t.string :pic_name
      t.string :pic_phone
      t.string :pic_mobile_phone
      t.string :pic_email
      t.text :address

      t.timestamps null: false
    end
  end
end
