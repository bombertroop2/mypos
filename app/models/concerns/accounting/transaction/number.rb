require 'active_support/concern'

module Accounting::Transaction::Number
  extend ActiveSupport::Concern

  def generate_number_transaction
    coa_code = AccountingAccount.find_by(id: coa_id).code rescue ""
    year = Time.now.strftime("%y")
    number = AccountingJurnalTransction.select(:id).where("number ->> 'code' = ? & number ->> 'year' = ?",  coa_code, year).size + 1
    coa_code+year+(sprintf '%010d', (number))
    return {code: coa_code, year: year, no: number}
  end

end
