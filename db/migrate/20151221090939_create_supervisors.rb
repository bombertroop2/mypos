class CreateSupervisors < ActiveRecord::Migration
  def change
    create_table :supervisors do |t|
      t.string :code
      t.string :name
      t.text :address
      t.string :email
      t.string :phone
      t.string :mobile_phone

      t.timestamps null: false
    end
  end
end
