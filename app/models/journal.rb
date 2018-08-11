class Journal < ApplicationRecord
  belongs_to :coa
  belongs_to :warehouse
  belongs_to :transactionable, :polymorphic => true
end
