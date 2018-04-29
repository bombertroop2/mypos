class AddImportBeginningStock < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :import_beginning_stock, :boolean, default: true
  end
end
