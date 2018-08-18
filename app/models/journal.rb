class Journal < ApplicationRecord
  belongs_to :coa
  belongs_to :warehouse
  belongs_to :transactionable, :polymorphic => true
  has_many :journal_discount_details
  has_many :journal_detail_bogos
  has_many :journal_detail_non_events
end
