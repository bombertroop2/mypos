class CreateAccountsReceivableInvoices < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts_receivable_invoices do |t|
      t.string :number
      t.text :note
      t.decimal :total
      t.decimal :remaining_debt
      t.date :due_date
      t.references :shipment, foreign_key: true, index: false

      t.timestamps
    end
    add_index :accounts_receivable_invoices, :number, unique: true
    add_index :accounts_receivable_invoices, :shipment_id, unique: true
  end
end
