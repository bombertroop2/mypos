class AddBeginningOfDueDateCalculatingToGeneralVariables < ActiveRecord::Migration[5.0]
  def change
    add_column :general_variables, :beginning_of_due_date_calculating, :string, default: "Delivery date"
  end
end
