class FiscalYear < ApplicationRecord
  audited on: [:create, :update]
  has_associated_audits

  has_many :fiscal_months, dependent: :destroy
  accepts_nested_attributes_for :fiscal_months

  validates :year, presence: true, uniqueness: true
  validates :year, numericality: {greater_than_or_equal_to: 1, less_than_or_equal_to: Date.current.year, only_integer: true}, if: proc { |fy| fy.year.present? }
    
    before_destroy :next_fiscal_not_existed, :delete_tracks
    
    private
    
    def next_fiscal_not_existed
      fy = FiscalYear.select(:year).where(["year > ?", year]).order(:year).first
      if fy.present?
        errors.add(:base, "Please delete fiscal #{fy.year} first")
        throw :abort
      end
    end
    
    def delete_tracks
      audits.destroy_all
    end
  end
