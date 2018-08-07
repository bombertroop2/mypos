class CreateJournals < ActiveRecord::Migration[5.0]
  def change
    create_table :journals do |t|
      t.references :coa, foreign_key: true
      t.integer :gross
      t.integer :gross_after_discount
      t.integer :discount
      t.integer :ppn
      t.integer :nett
      t.references :transactionable, polymorphic: true
      t.boolean :fiscal_is_closed?, default: false
      t.timestamps
    end
    add_index :journals, :fiscal_is_closed?
  end
end
