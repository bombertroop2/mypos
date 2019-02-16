class AddBeginningOfDebtRecordingToGeneralVariables < ActiveRecord::Migration[5.0]
  def change
    add_column :general_variables, :beginning_of_debt_recording, :string
  end
end
