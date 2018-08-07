class Journal < ApplicationRecord
  belongs_to :coa_department
  belongs_to :transactionable, :polymorphic => true
end
