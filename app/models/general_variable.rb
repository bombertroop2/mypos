class GeneralVariable < ApplicationRecord
  #  validates :pieces_per_koli, :inventory_valuation_method, :beginning_of_debt_recording, presence: true
  validates :pieces_per_koli, :beginning_of_account_payable_creating, :beginning_of_due_date_calculating, presence: true
  validates :pieces_per_koli, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc{|gv| gv.pieces_per_koli.present? && gv.pieces_per_koli_changed?}
    validate :beginning_of_account_payable_creating_available, :beginning_of_due_date_calculating_available
    #    validate :inventory_valuation_method_available, :beginning_of_debt_recording_available
    
    #    INVENTORY_VALUATION_METHODS = [
    #      ["FIFO", "FIFO"],
    #      ["AVG", "AVG"]
    #    ]
    #
    #    BEGINNING_OF_DEBT_RECORDINGS = [
    #      ["Receiving", "Receiving"],
    #      ["AP Invoice", "AP Invoice"]
    #    ]
    
    BEGINNING_OF_AP_CREATINGS = [
      ["Closed/Finish", "Closed/Finish"],
      ["Partial", "Partial"]
    ]

    BEGINNING_OF_DUE_DATE_CALCULATINGS = [
      ["Delivery date", "Delivery date"],
      ["Invoice date", "Invoice date"]
    ]
    
    private
    
    #    def inventory_valuation_method_available
    #      INVENTORY_VALUATION_METHODS.select{ |x| x[1] == inventory_valuation_method }.first.first
    #    rescue
    #      errors.add(:inventory_valuation_method, "does not exist!") if inventory_valuation_method.present?
    #    end
    #    def beginning_of_debt_recording_available
    #      BEGINNING_OF_DEBT_RECORDINGS.select{ |x| x[1] == beginning_of_debt_recording }.first.first
    #    rescue
    #      errors.add(:beginning_of_debt_recording, "does not exist!") if beginning_of_debt_recording.present?
    #    end
    def beginning_of_account_payable_creating_available
      BEGINNING_OF_AP_CREATINGS.select{ |x| x[1] == beginning_of_account_payable_creating }.first.first
    rescue
      errors.add(:beginning_of_account_payable_creating, "does not exist!") if beginning_of_account_payable_creating.present?
    end

    def beginning_of_due_date_calculating_available
      BEGINNING_OF_DUE_DATE_CALCULATINGS.select{ |x| x[1] == beginning_of_due_date_calculating }.first.first
    rescue
      errors.add(:beginning_of_due_date_calculating, "does not exist!") if beginning_of_due_date_calculating.present?
    end
  end
