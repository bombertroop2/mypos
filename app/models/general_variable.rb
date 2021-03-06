class GeneralVariable < ApplicationRecord
  attr_accessor :attr_path_to_bartender_file
  
  validates :beginning_of_account_payable_creating, presence: true
  validates :pieces_per_koli, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc{|gv| gv.pieces_per_koli.present? && gv.pieces_per_koli_changed?}
    validate :beginning_of_account_payable_creating_available
    
    before_save :get_bartender_file_path
    
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
    
    def get_bartender_file_path
      if attr_path_to_bartender_file.present?
        self.path_to_bartender_file = File.absolute_path(attr_path_to_bartender_file.original_filename)
      end
    end
        
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
  end
