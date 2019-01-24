class GeneralVariable < ApplicationRecord
  validates :pieces_per_koli, :inventory_valuation_method, :beginning_of_debt_recording, presence: true
  validates :pieces_per_koli, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc{|gv| gv.pieces_per_koli.present? && gv.pieces_per_koli_changed?}
    validate :inventory_valuation_method_available, :beginning_of_debt_recording_available
    
    INVENTORY_VALUATION_METHODS = [
      ["FIFO", "FIFO"],
      ["AVG", "AVG"]
    ]

    BEGINNING_OF_DEBT_RECORDINGS = [
      ["Receiving", "Receiving"],
      ["AP Invoice", "AP Invoice"]
    ]
    
    private
    
    def inventory_valuation_method_available
      INVENTORY_VALUATION_METHODS.select{ |x| x[1] == inventory_valuation_method }.first.first
    rescue
      errors.add(:inventory_valuation_method, "does not exist!") if inventory_valuation_method.present?
    end

    def beginning_of_debt_recording_available
      BEGINNING_OF_DEBT_RECORDINGS.select{ |x| x[1] == beginning_of_debt_recording }.first.first
    rescue
      errors.add(:beginning_of_debt_recording, "does not exist!") if beginning_of_debt_recording.present?
    end
  end