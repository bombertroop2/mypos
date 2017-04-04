class AllocatedReturnItem < ApplicationRecord
  belongs_to :account_payable
  belongs_to :purchase_return
end
