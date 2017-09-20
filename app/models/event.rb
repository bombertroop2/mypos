class Event < ApplicationRecord
  attr_accessor :type
  
  has_many :event_warehouses, dependent: :destroy
  
  before_validation :remove_white_space, :upcase_code
  validates :code, :name, :start_date_time, :end_date_time, presence: true
  validates :first_plus_discount, presence: true, if: proc{|event| event.type.strip.eql?("")}
    validates :cash_discount, presence: true, if: proc{|event| event.type.strip.eql?("cash discount")}
      validates :start_date_time, date: {after_or_equal_to: proc {Time.current}, message: 'must be after or equal to current time' }, if: proc{|evnt| evnt.start_date_time.present? && evnt.start_date_time_changed?}
        validates :end_date_time, date: {after: proc {|evnt| evnt.start_date_time}, message: 'must be after start time' }, if: proc{|evnt| evnt.start_date_time.present? && evnt.end_date_time.present?}
          validates :first_plus_discount, numericality: {greater_than: 0, less_than: 100}, if: proc {|evnt| evnt.first_plus_discount.present? && evnt.type.strip.eql?("")}
            validates :second_plus_discount, numericality: {greater_than: 0, less_than: 100}, if: proc {|evnt| evnt.second_plus_discount.present? && evnt.type.strip.eql?("")}
              validates :cash_discount, numericality: {greater_than: 0}, if: proc { |event| event.type.strip.eql?("cash discount") && event.cash_discount.present? }
                validates :special_price, presence: true, if: proc{|event| event.type.strip.eql?("special price")}
                  validates :special_price, numericality: {greater_than: 0}, if: proc { |event| event.type.strip.eql?("special price") && event.special_price.present? }

                    accepts_nested_attributes_for :event_warehouses, allow_destroy: true
                    
                    private
                    
  
                    def remove_white_space
                      self.code = code.strip
                      self.name = name.strip
                    end

                    def upcase_code
                      self.code = code.upcase
                    end
                  end
