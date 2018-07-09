class AddIsDocumentPrintedToShipments < ActiveRecord::Migration[5.0]
  def change
    add_column :shipments, :is_document_printed, :boolean, default: false
  end
end
