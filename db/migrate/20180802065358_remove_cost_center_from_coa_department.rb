class RemoveCostCenterFromCoaDepartment < ActiveRecord::Migration[5.0]
  def change
    remove_column :coa_departments, :cost_center, :string
    remove_index :coa_departments, [:department_id, :coa_id]
    add_index :coa_departments, [:department_id, :coa_id, :warehouse_id], unique: true, :name => 'coa_department_retation_index'
  end
end
