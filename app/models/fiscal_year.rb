class FiscalYear < ApplicationRecord
  audited
  has_associated_audits

  has_many :fiscal_months, dependent: :destroy
  accepts_nested_attributes_for :fiscal_months

  validates :year, presence: true, uniqueness: true
  validates :year, numericality: {greater_than_or_equal_to: 1, less_than_or_equal_to: Date.current.year, only_integer: true}, if: proc { |fy| fy.year.present? }
  end
