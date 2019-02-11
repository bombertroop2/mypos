class CompanyBankAccountNumber < ApplicationRecord
  attr_accessor :attr_bank_code
  
  belongs_to :company_bank

  before_validation :strip_field_values

  validates :account_number, presence: true
  validates :account_number, uniqueness: { scope: :company_bank_id }, if: proc{|cban| cban.account_number.present? && cban.account_number_changed?}
    validate :account_number_not_duplicated, if: proc{|cban| cban.account_number.present? && cban.account_number_changed? && cban.attr_bank_code.present?}

      before_save :upcase_account_number

      private
      
      def account_number_not_duplicated
        errors.add(:account_number, "has already been taken") if CompanyBankAccountNumber.select("1 AS one").joins(:company_bank).where(["company_bank_account_numbers.account_number = ? AND company_banks.code = ?", account_number, attr_bank_code]).present?
      end
  
      def upcase_account_number
        self.account_number = account_number.upcase
      end
  
      def strip_field_values
        self.account_number = account_number.strip.gsub(" ","").gsub("\t","")
      end
    end
