class CreateCustomers < ActiveRecord::Migration[5.0]
  def change
    create_table :customers do |t|
      t.string :code
      t.string :name
      t.string :phone
      t.string :facsimile
      t.string :email
      t.string :pic_name
      t.string :pic_mobile_phone
      t.string :pic_email
      t.text :address
      t.integer :terms_of_payment
      t.boolean :is_taxable_entrepreneur, default: true
      t.string :value_added_tax
      t.decimal :limit_value
      t.text :deliver_to

      t.timestamps
    end
    add_index :customers, :code, unique: true
  end
end


