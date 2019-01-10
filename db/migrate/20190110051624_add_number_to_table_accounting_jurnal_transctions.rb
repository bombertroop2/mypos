class AddNumberToTableAccountingJurnalTransctions < ActiveRecord::Migration[5.0]
  def change
    add_column :accounting_jurnal_transctions, :number, :jsonb
  end
end
