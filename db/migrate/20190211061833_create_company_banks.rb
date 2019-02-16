class CreateCompanyBanks < ActiveRecord::Migration[5.0]
  def change
    create_table :company_banks do |t|
      t.references :company, foreign_key: true, index: false
      t.string :code
      t.string :name

      t.timestamps
    end
    add_index :company_banks, [:company_id, :code], unique: true
  end
end
