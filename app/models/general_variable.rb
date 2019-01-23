class GeneralVariable < ApplicationRecord
  validates :pieces_per_koli, :inventory_valuation_method, presence: true
  validates :pieces_per_koli, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc{|gv| gv.pieces_per_koli.present? && gv.pieces_per_koli_changed?}
    validate :inventory_valuation_method_available
    
    INVENTORY_VALUATION_METHODS = [
      ["FIFO", "FIFO"],
      ["AVG", "AVG"]
    ]
    
    private
    
    def inventory_valuation_method_available
      INVENTORY_VALUATION_METHODS.select{ |x| x[1] == inventory_valuation_method }.first.first
    rescue
      errors.add(:inventory_valuation_method, "does not exist!") if inventory_valuation_method.present?
    end
  end
