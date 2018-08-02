class RemoveCompanyIdFromCoaAndCoaDepartmentAndDepartment < ActiveRecord::Migration[5.0]
  def change
    CoaDepartment.delete_all
    Department.delete_all
    Coa.delete_all
    remove_index :coas, column: [:company_id, :code]
    remove_index :departments, column: [:company_id, :code]
    remove_reference :coas, :company, index:true, foreign_key: true
    remove_reference :departments, :company, index:true, foreign_key: true
    remove_reference :coa_departments, :company, index:true, foreign_key: true
    add_index :coas, :code, unique: true
    add_index :coas, :transaction_type, unique: true
    add_index :departments, :code, unique: true
  end
end
