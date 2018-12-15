class RenameFieldTypeToTypeJurnalOnAccoutingJurnalTranscations < ActiveRecord::Migration[5.0]
  def up
    rename_column :accounting_jurnal_transctions, :type, :type_jurnal
  end

  def down
    rename_column :accounting_jurnal_transctions, :type_jurnal, :type
  end
end
