class CreateMembers < ActiveRecord::Migration[5.0]
  def change
    create_table :members do |t|
      t.string :name
      t.string :address
      t.string :phone
      t.string :mobile_phone
      t.string :gender
      t.string :email

      t.timestamps
    end
  end
end
