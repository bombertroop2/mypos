class CashierOpening < ApplicationRecord
  attr_accessor :update_cash_balance, :closing_cashier, :user_id
  
  belongs_to :warehouse
  belongs_to :user, class_name: "User", foreign_key: :opened_by
  has_many :cash_disbursements, dependent: :destroy
  
  before_validation :set_open_time, if: proc{|co| !co.update_cash_balance && !co.closing_cashier}
  
    validates :shift, :station, :beginning_cash, presence: true, if: proc{|co| !co.update_cash_balance && !co.closing_cashier}
      validates :beginning_cash, numericality: {greater_than_or_equal_to: 0}, if: proc { |co| !co.update_cash_balance && co.beginning_cash.present? && !co.closing_cashier}
        validates :station, uniqueness: { scope: [:warehouse_id, :open_date, :shift], message: "has already been opened" }, if: proc{|co| !co.update_cash_balance && !co.closing_cashier}
          validate :station_available, :shift_available, :second_shift_allowable, :today_cashier_openable, if: proc{|co| !co.update_cash_balance && !co.closing_cashier}
            validate :closable, if: proc{|co| co.closing_cashier}

              before_create :set_cash_balance
    
              STATIONS = [
                ["1", "1"],
                ["2", "2"],
                ["3", "3"]
              ]

              SHIFTS = [
                ["1", "1"],
                ["2", "2"]
              ]
    

              private
            
              def closable
                self.closed_at = open_date.end_of_day if open_date != Date.current
                errors.add(:base, "Sorry, cashier cannot be closed") if opened_by != user_id || closed_at_was.present?
              end
    
              def set_cash_balance
                self.cash_balance = beginning_cash
              end
    
              def today_cashier_openable
                errors.add(:base, "Previous cashier is open, please close it first") if CashierOpening.select("1 AS one").where(warehouse_id: warehouse_id).where("closed_at IS NULL").where(["open_date <> ?", @current_date]).where("opened_by = #{opened_by}").present?
              end
    
              def second_shift_allowable      
                first_shift = CashierOpening.select(:closed_at).where(warehouse_id: warehouse_id, station: station, shift: "1", open_date: @current_date).first
                errors.add(:shift, "is not allowed!") if shift.eql?("2") && station.present? && (first_shift.blank? || first_shift.closed_at.nil?)
              end
    
              def station_available
                STATIONS.select{ |x| x[1] == station }.first.first
              rescue
                errors.add(:station, "does not exist!") if station.present?
              end

              def shift_available
                SHIFTS.select{ |x| x[1] == shift }.first.first
              rescue
                errors.add(:shift, "does not exist!") if shift.present?
              end
      
              def set_open_time
                @current_date = Date.current
                self.open_date = @current_date
              end
            end
