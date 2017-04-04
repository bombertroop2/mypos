class CreateAllocatedReturnItems < ActiveRecord::Migration[5.0]
  def change
    create_table :allocated_return_items do |t|
      t.references :account_payable, foreign_key: true
      t.references :purchase_return, foreign_key: true

      t.timestamps
    end
  end
end
