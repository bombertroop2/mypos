class CashDisbursement < ApplicationRecord
  attr_accessor :user_id, :cashier
  
  belongs_to :cashier_opening

  validates :description, :price, presence: true
  validate :warehouse_is_active, :cashier_open
  validates :price, numericality: {greater_than: 0, less_than_or_equal_to: :cash_balance}, if: proc { |cd| cd.price.present? && cd.cashier.present? }

    before_create :update_cash_balance, :set_cashier_opening_id

    private
    
    def warehouse_is_active
      errors.add(:base, "Sorry, warehouse is not active") if user_id.present? && Warehouse.joins(sales_promotion_girls: :user).select("1 AS one").where(:"users.id" => user_id).where(["warehouses.is_active = ?", true]).blank?
    end
    
    def set_cashier_opening_id
      self.cashier_opening_id = cashier.id
    end
    
    def update_cash_balance
      self.cashier.update cash_balance: (cashier.cash_balance - price), update_cash_balance: true
    end
    
    def cash_balance
      cashier.cash_balance
    end
    
    def cashier_open
      self.cashier = CashierOpening.select(:id, :cash_balance).joins(:warehouse).where(opened_by: user_id, open_date: Date.current, :"warehouses.is_active" => true).where("closed_at IS NULL").first
      errors.add(:base, "Please open cashier first") if cashier.blank?
    end
  end  
