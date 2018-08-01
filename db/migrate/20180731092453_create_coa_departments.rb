class CreateCoaDepartments < ActiveRecord::Migration[5.0]
  def change
    create_table :coa_departments do |t|
      t.references :company, foreign_key: true
      t.references :department, foreign_key: true
      t.references :coa, foreign_key: true
      t.string :cost_center
      t.references :warehouse, foreign_key: true
      t.string :location

      t.timestamps
    end
    add_index :coa_departments, [:department_id, :coa_id], unique: true
  end
end
