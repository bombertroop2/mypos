class CounterEvent < ApplicationRecord
  attr_accessor :event_activation # ==> ga dipake
  attr_accessor :attr_importing_data

  audited on: [:create, :update]

  has_many :counter_event_warehouses, dependent: :destroy
  has_many :consignment_sales, dependent: :restrict_with_error
                
  before_validation :remove_white_space, :upcase_code
  
	validates :code, :name, :start_time, :end_time, :counter_event_type, presence: true
  validate :different_type_not_added
  validate :same_range_not_added
  validates :counter_event_type, inclusion: { in: ["Discount(%)", "Special Price"],
    message: "%{value} is not a valid type" }
  validates :first_discount, presence: true, if: proc{|counter_event| counter_event.counter_event_type.strip.eql?("Discount(%)")}
    validates :start_time, date: {after_or_equal_to: proc {Time.current}, message: 'must be after or equal to current time' }, if: proc{|evnt| evnt.start_time.present? && evnt.start_time_changed? && !evnt.attr_importing_data}
      validates :end_time, date: {after: proc {|evnt| evnt.start_time}, message: 'must be after start time' }, if: proc{|evnt| evnt.start_time.present? && evnt.end_time.present?}
        validates :first_discount, numericality: {less_than_or_equal_to: 100}, if: proc {|evnt| evnt.first_discount.present? && evnt.counter_event_type.strip.eql?("Discount(%)")}
          validates :first_discount, numericality: {greater_than: 0}, if: proc {|evnt| evnt.first_discount.present? && evnt.counter_event_type.strip.eql?("Discount(%)") && !evnt.attr_importing_data}
            validates :second_discount, numericality: {greater_than: 0, less_than: 100}, if: proc {|evnt| evnt.second_discount.present? && evnt.counter_event_type.strip.eql?("Discount(%)")}
              validates :margin, numericality: {greater_than_or_equal_to: 0, less_than: 100}
              validates :participation, numericality: {greater_than_or_equal_to: 0, less_than: 100}
              validates :special_price, presence: true, if: proc{|counter_event| counter_event.counter_event_type.strip.eql?("Special Price")}
                validates :special_price, numericality: {greater_than: 0}, if: proc { |counter_event| counter_event.counter_event_type.strip.eql?("Special Price") && counter_event.special_price.present? }
                  validate :editable, on: :update, unless: proc {|event| event.event_activation.eql?("true")}
  
                    accepts_nested_attributes_for :counter_event_warehouses, allow_destroy: true
                
                    before_update :delete_old_warehouses, unless: proc{|ce| ce.event_activation.eql?("true")}
                      before_destroy :deletable, :delete_tracks
	
                      # ga kepake ????
                      def set_warehouses(w_ids)
                        counter_event_warehouses.destroy_all
                        warehouse_ids = w_ids.split(",")
                        arr = warehouse_ids.map {|x| {counter_event_id: id, warehouse_id: x}}
		
                        CounterEventWarehouse.create(arr)
                      end
  
                      def code_and_name
                        "#{code} - #{name}"
                      end

                      private
                    
                      def same_range_not_added
                        errors.add(:start_time, "has already been taken") if code.present? && start_time.present? && (code_changed? || start_time_changed?) && CounterEvent.select("1 AS one").where(["code = ? AND DATE(start_time) <= ? AND DATE(end_time) >= ? AND counter_event_type = ?", code, start_time.to_date, start_time.to_date, counter_event_type]).present?
                        errors.add(:end_time, "has already been taken") if code.present? && end_time.present? && (code_changed? || end_time_changed?) && CounterEvent.select("1 AS one").where(["code = ? AND DATE(start_time) <= ? AND DATE(end_time) >= ? AND counter_event_type = ?", code, end_time.to_date, end_time.to_date, counter_event_type]).present?
                      end
                    
                      def different_type_not_added
                        errors.add(:code, "has already been taken") if code.present? && code_changed? && CounterEvent.select("1 AS one").where(["code = ? AND counter_event_type <> ?", code, counter_event_type]).present?
                      end
                  
                      def delete_old_warehouses
                        counter_event_warehouses.select(:id).each do |counter_event_warehouse|
                          counter_event_warehouse.destroy if !counter_event_warehouse.new_record?
                        end
                      end
                  
                      def delete_tracks
                        audits.destroy_all
                      end
                    
                      def deletable
                        if start_time <= Time.current
                          errors.add(:base, "The record cannot be deleted")
                          throw :abort
                        end
                      end

                      def editable
                        errors.add(:base, "The record cannot be edited") if start_time <= Time.current
                      end

                      def remove_white_space
                        self.code = code.strip
                        self.name = name.strip
                      end

                      def upcase_code
                        self.code = code.upcase.gsub(" ","").gsub("\t","")
                      end
                    end
