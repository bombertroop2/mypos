class CreateDepartments < ActiveRecord::Migration[5.0]
  def change
    create_table :departments do |t|
      t.string :code
      t.string :name
      t.text :description
      t.references :company, foreign_key: true

      t.timestamps
    end
    add_index :departments, [:company_id, :code], unique: true
  end
end
