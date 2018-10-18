class Warehouse < ApplicationRecord
  audited on: [:create, :update]
  belongs_to :supervisor
  belongs_to :region
  belongs_to :price_code

  has_many :event_warehouses, dependent: :restrict_with_error
  has_many :listing_stocks, dependent: :restrict_with_error
  has_many :purchase_orders, dependent: :restrict_with_error
  has_many :sales_promotion_girls, dependent: :restrict_with_error
  has_many :direct_purchases, dependent: :restrict_with_error
  has_many :cashier_openings, dependent: :restrict_with_error
  has_many :counter_event_warehouses, dependent: :restrict_with_error
  has_many :consignment_sales, dependent: :restrict_with_error
  has_many :sales, through: :cashier_openings
  has_many :origin_warehouse_order_bookings, class_name: "OrderBooking", foreign_key: :origin_warehouse_id, dependent: :restrict_with_error
  has_many :destination_warehouse_order_bookings, class_name: "OrderBooking", foreign_key: :destination_warehouse_id, dependent: :restrict_with_error
  has_many :origin_warehouse_stock_mutations, class_name: "StockMutation", foreign_key: :origin_warehouse_id, dependent: :restrict_with_error
  has_many :destination_warehouse_stock_mutations, class_name: "StockMutation", foreign_key: :destination_warehouse_id, dependent: :restrict_with_error
  has_one :stock, dependent: :restrict_with_error
  has_many :targets, dependent: :restrict_with_error
  has_one :po_relation, -> {select("1 AS one")}, class_name: "PurchaseOrder"
  has_one :spg_relation, -> {select("1 AS one")}, class_name: "SalesPromotionGirl"
  has_one :origin_warehouse_order_booking_relation, -> {select("1 AS one")}, class_name: "OrderBooking", foreign_key: :origin_warehouse_id
  has_one :destination_warehouse_order_booking_relation, -> {select("1 AS one")}, class_name: "OrderBooking", foreign_key: :destination_warehouse_id
  has_one :origin_warehouse_stock_mutation_relation, -> {select("1 AS one")}, class_name: "StockMutation", foreign_key: :origin_warehouse_id
  has_one :destination_warehouse_stock_mutation_relation, -> {select("1 AS one")}, class_name: "StockMutation", foreign_key: :destination_warehouse_id
  has_one :event_warehouse_relation, -> {select("1 AS one")}, class_name: "EventWarehouse"
  has_one :cashier_opening_relation, -> {select("1 AS one")}, class_name: "CashierOpening"
  has_one :consignment_sale_relation, -> {select("1 AS one")}, class_name: "ConsignmentSale"
  has_one :selected_columns_stock, -> {select(:id, :warehouse_id)}, class_name: "Stock"
  has_one :counter_event_warehouse_relation, -> {select("1 AS one")}, class_name: "CounterEventWarehouse"
  has_many :stock_products, -> {select(:stock_id, :product_id, :code).joins(:product)}, through: :selected_columns_stock
  has_one :target_relation, -> {select("1 AS one")}, class_name: "Target"

  validates :code, :name, :warehouse_type, presence: true
  validates :supervisor_id, :region_id, :price_code_id, :address, presence: true, unless: proc{|warehouse| warehouse.warehouse_type.eql?("in_transit")}
    validates :sku, :counter_type, presence: true, if: proc{|warehouse| warehouse.warehouse_type.present? && warehouse.warehouse_type.include?("ctr")}
      validates :code, length: {maximum: 9}, if: Proc.new {|warehouse| warehouse.code.present?}
        validate :code_not_changed, :is_area_manager_valid_to_supervise_this_warehouse?,
          :area_manager_available, :region_available, :price_code_available, :type_available,
          :warehouse_type_not_changed, :code_not_emptied, :code_not_invalid, :price_code_not_changed,
          :in_transit_present, :counter_type_not_changed#, :central_present
        validate :counter_type_available, if: proc{|wr| wr.warehouse_type.present? && wr.warehouse_type.include?("ctr")}

          before_validation :delete_non_intransit_attributes, if: proc{|warehouse| warehouse.warehouse_type.eql?("in_transit")}
            before_validation :upcase_code, :strip_string_values
            before_validation :activate_warehouse, on: :create
            before_validation :delete_sku_value, :delete_counter_type_value, if: proc{|warehouse| warehouse.warehouse_type.present? && !warehouse.warehouse_type.include?("ctr")}
              before_save :empty_messages, unless: proc{|warehouse| warehouse.warehouse_type.eql?("showroom")}
                before_destroy :delete_tracks

                TYPES = [
                  ["Central", "central"],
                  ["Showroom", "showroom"],
                  ["In Transit", "in_transit"],
                  ["CTR Matahari", "ctr_matahari"],
                  ["CTR Ramayana", "ctr_ramayana"],
                  ["CTR Non Ramayana", "ctr_non_ramayana"],
                  ["CTR SOGO", "ctr_sogo"],
                  ["CTR Metro", "ctr_metro"],
                  ["CTR Uniqlo", "ctr_uniqlo"]
                ]

                COUNTER_TYPES = [
                  ["Men", "Men"],
                  ["Ladies", "Ladies"],
                  ["Kids", "Kids"],
                  ["Bags", "Bags"],
                  ["Bazar", "Bazar"]
                ]

                def code_and_name
                  "#{code} - #{name}"
                end

                def self.has_supervisor?(id)
                  SalesPromotionGirl.where(["warehouse_id = ? AND role = 'supervisor'", id]).select("1 AS one").present?
                end

                def self.central
                  where(warehouse_type: "central")
                end

                def self.actived
                  where(is_active: true)
                end

                def self.not_central
                  where("warehouse_type <> 'central'")
                end

                def self.not_in_transit
                  where("warehouse_type <> 'in_transit'")
                end

                def self.showroom
                  where("warehouse_type = 'showroom'")
                end

                def self.counter
                  where("warehouse_type LIKE 'ctr%'")
                end

                private

                def delete_non_intransit_attributes
                  self.address = nil
                  self.supervisor_id = nil
                  self.region_id = nil
                  self.price_code_id = nil
                  self.first_message = nil
                  self.second_message = nil
                  self.third_message = nil
                  self.fourth_message = nil
                  self.fifth_message = nil
                  self.sku = nil
                  self.counter_type = nil
                end

                # untuk sekarang asumsikan warehouse selalu aktif
                def activate_warehouse
                  self.is_active = true
                end

                def delete_counter_type_value
                  self.counter_type = nil
                end

                def delete_sku_value
                  self.sku = nil
                end

                def code_not_invalid
                  unless code.eql?("-")
                    if code.include?(" ")
                      errors.add(:code, "is not valid")
                    else
                      splitted_code = code.split("-")
                      if splitted_code.length != 2
                        errors.add(:code, "is not valid")
                      else
                        errors.add(:code, "is not valid") if splitted_code[0].length < 3 || splitted_code[1].length < 3 || splitted_code[0].length > 4 || splitted_code[1].length > 4
                      end
                    end
                  end
                end

                def code_not_emptied
                  errors.add(:code, "can't be blank") if code.eql?("-")
                end

                def empty_messages
                  self.first_message = self.second_message = self.third_message = self.fourth_message = self.fifth_message = ""
                end

                def in_transit_present
                  if warehouse_type_changed?
                    in_transit = Warehouse.where(warehouse_type: "in_transit").select("1 AS one")
                    if in_transit.present?
                      errors.add(:warehouse_type, "has already been taken") if warehouse_type.present? && warehouse_type.eql?("in_transit")
                    end
                  end
                end

#                def central_present
#                  if warehouse_type_changed?
#                    central_warehouse = Warehouse.where(warehouse_type: "central").select("1 AS one")
#                    if central_warehouse.present?
#                      errors.add(:warehouse_type, "has already been taken") if warehouse_type.present? && warehouse_type.eql?("central")
#                    end
#                  end
#                end

                def delete_tracks
                  audits.destroy_all
                end

                def strip_string_values
                  self.code = code.gsub("_"," ").strip
                  self.sku = sku.gsub(" ","").gsub("\t","") if sku.present?
                end

                def area_manager_available
                  errors.add(:supervisor_id, "does not exist!") if supervisor_id.present? && Supervisor.where(id: supervisor_id).select("1 AS one").blank?
                end

                def region_available
                  errors.add(:region_id, "does not exist!") if region_id.present? && Region.where(id: region_id).select("1 AS one").blank?
                end

                def price_code_available
                  errors.add(:price_code_id, "does not exist!") if price_code_id.present? && PriceCode.where(id: price_code_id).select("1 AS one").blank?
                end

                def type_available
                  TYPES.select{ |x| x[1] == warehouse_type }.first.first
                rescue
                  errors.add(:warehouse_type, "does not exist!") if warehouse_type.present?
                end

                def counter_type_available
                  COUNTER_TYPES.select{ |x| x[1] == counter_type }.first.first
                rescue
                  errors.add(:counter_type, "does not exist!") if counter_type.present?
                end

                def is_area_manager_valid_to_supervise_this_warehouse?
                  warehouse_types = Warehouse.where(supervisor_id: supervisor_id).pluck(:warehouse_type)
                  if warehouse_types.present? && warehouse_type.present?
                    # hapus duplikat elemen dan replace type yang mengandung prefix ctr_ ke counter
                    replaced_warehouse_types = warehouse_types.map do |wt|
                      if wt.include?("ctr")
                        "counter"
                      else
                        wt
                      end
                    end.uniq
                    # apabila tipe yang dipilih showroom atau mengandung prefix ctr (counter), maka tampilkan error jika warehouse tipe yang di supervisi sebelumnya adalah selain showroom dan counter
                    if warehouse_type.include?("ctr") || warehouse_type.eql?("showroom")
                      errors.add(:supervisor_id, "should manage the warehouse with type #{replaced_warehouse_types.to_sentence}") if !replaced_warehouse_types.include?("counter") && !replaced_warehouse_types.include?("showroom")
                    else
                      errors.add(:supervisor_id, "should manage the warehouse with type #{replaced_warehouse_types.to_sentence}") if !replaced_warehouse_types.include?(warehouse_type)
                    end
                  end
                end

                def upcase_code
                  self.code = code.upcase
                end

                def code_not_changed
                  errors.add(:code, "change is not allowed!") if code_changed? && persisted? && (event_warehouse_relation.present? || spg_relation.present? || po_relation.present? || stock.present? || destination_warehouse_order_booking_relation.present? || origin_warehouse_order_booking_relation.present? || origin_warehouse_stock_mutation_relation.present? || destination_warehouse_stock_mutation_relation.present? || cashier_opening_relation.present? || consignment_sale_relation.present? || counter_event_warehouse_relation.present? || target_relation.present?)
                end

                def warehouse_type_not_changed
                  errors.add(:warehouse_type, "change is not allowed!") if warehouse_type_changed? && persisted? && (event_warehouse_relation.present? || destination_warehouse_order_booking_relation.present? || origin_warehouse_order_booking_relation.present? || po_relation.present? || spg_relation.present? || origin_warehouse_stock_mutation_relation.present? || destination_warehouse_stock_mutation_relation.present? || cashier_opening_relation.present? || consignment_sale_relation.present? || counter_event_warehouse_relation.present?)
                end

                def price_code_not_changed
                  errors.add(:price_code_id, "change is not allowed!") if price_code_id_changed? && persisted? && (cashier_opening_relation.present? || consignment_sale_relation.present?)
                end
                
                def counter_type_not_changed
                  errors.add(:counter_type, "change is not allowed!") if counter_type_changed? && persisted? && destination_warehouse_order_booking_relation.present?
                end
              end
