class ImportDataEmailJob < ApplicationJob
  queue_as :default

  def perform(type, errors, xls_error_index)    
    DuosMailer.import_data_email(type, errors, xls_error_index).deliver
  end
end
