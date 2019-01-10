require 'active_support/concern'

module Accounting::Coa
  extend ActiveSupport::Concern

  included do
    after_create :generate_coa_child
  end


  def generate_coa_child
    number = AccountingAccount.find_by(id: coa_id)
    x= 1
    loop do
      new_code =  number.first_2_code + (sprintf '%03d',(number.last_3_code + x))
      if (AccountingAccount.where(code: new_code).present?)
        x += 1
      else
        new_account = number.attributes.slice("code", "classificatio", "category_id")
        .symbolize_keys
        .merge({code: "new_code", parent_id: number.id, description: generate_code_descripton(number) })
        new_account = AccountingAccount.create(new_account)
        self.update_column(coa_id: new_account.coa_id)
        break
      end
    end
  end

  def generate_code_descripton(number)
    if self.class.to_s.eql?("Warehouse")
      "Petty cash #{self.code}"
    else
      name rescue number[:description]
    end
  end


end
