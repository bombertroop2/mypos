class CreateCompanies < ActiveRecord::Migration[5.0]
  def change
    create_table :companies do |t|
      t.string :code
      t.string :name
      t.string :taxpayer_registration_number
      t.text :address
      t.string :phone
      t.string :fax
      t.integer :total_showroom
      t.integer :total_counter

      t.timestamps
    end
  end
end
