class CreateAccountingAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :accounting_accounts do |t|
      t.string :code
      t.string :description
      t.integer :classification
      t.integer :category_id
      t.integer :parent_id

      t.timestamps
    end
  end

end
