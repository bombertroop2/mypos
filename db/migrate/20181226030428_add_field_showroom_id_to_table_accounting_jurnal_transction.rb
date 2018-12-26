class AddFieldShowroomIdToTableAccountingJurnalTransction < ActiveRecord::Migration[5.0]
  def change
    add_column :accounting_jurnal_transctions, :warehouse_id, :integer, index: true
  end
end
