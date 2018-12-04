class CreateAccountingAccountCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :accounting_account_categories do |t|
      t.string :name
      t.integer :parent_id
      t.integer :classification

      t.timestamps
    end
  end
end
