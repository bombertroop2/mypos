class PackingList < ApplicationRecord
  attr_accessor :attr_courier_id, :attr_courier_way_id, :attr_city_id, :attr_courier_price_type, :attr_creating_ap_invoice,
    :attr_gross_amount, :attr_vat_in_money, :attr_net_amount
  
  audited on: :create
  belongs_to :courier
  belongs_to :courier_way
  belongs_to :courier_unit
  belongs_to :city
  belongs_to :courier_price
  has_many :packing_list_items, dependent: :destroy
  
  before_validation :delete_courier_price_type, unless: proc{|pl| pl.attr_creating_ap_invoice}

    validates :id, presence: true, if: proc{|pl| pl.attr_creating_ap_invoice}
      validates :attr_courier_id, :departure_date, :attr_courier_way_id, :courier_unit_id, presence: true, unless: proc{|pl| pl.attr_creating_ap_invoice}
        validates :attr_courier_price_type, presence: true, if: proc{|pl| pl.attr_courier_id.present? && @courier.status.eql?("External") && !pl.attr_creating_ap_invoice}
          validates :attr_city_id, presence: true, if: proc{|pl| pl.attr_courier_id.present? && @courier.status.eql?("External") && !pl.attr_creating_ap_invoice}
            validate :courier_available, if: proc{|pl| pl.attr_courier_id.present? && !pl.attr_creating_ap_invoice}
              validate :courier_price_type_available, if: proc {|pl| pl.attr_courier_price_type.present? && pl.attr_courier_id.present? && pl.attr_courier_way_id.present? && pl.courier_unit_id.present? && pl.attr_city_id.present? && @courier.status.eql?("External") && !pl.attr_creating_ap_invoice}
                validate :via_available, if: proc{|pl| pl.attr_courier_way_id.present? && !pl.attr_creating_ap_invoice}
                  validate :unit_available, if: proc{|pl| pl.courier_unit_id.present? && pl.courier_unit_id_changed? && !pl.attr_creating_ap_invoice}
                    validate :city_available, if: proc {|pl| pl.attr_city_id.present? && pl.attr_courier_id.present? && pl.attr_courier_way_id.present? && pl.courier_unit_id.present? && @courier.status.eql?("External") && !pl.attr_creating_ap_invoice}
                      validate :transaction_open, :courier_price_available, :check_min_shipment_per_pl, unless: proc{|pl| pl.attr_creating_ap_invoice}

                        before_create :generate_number, :set_status
                        before_create :get_courier_price, if: proc{@courier.status.eql?("External")}
                          before_destroy -> {transaction_open("delete")}
                          before_destroy :record_not_deleted, :delete_tracks

                          accepts_nested_attributes_for :packing_list_items, allow_destroy: true

                          STATUSES = [
                            ["Delivered", "Delivered"],
                            ["Paid Off", "Paid Off"]
                          ]
            
                          private
                                                                                          
                          def get_courier_price
                            cp = CourierPrice.select(:id).where(city_id: attr_city_id, price_type: attr_courier_price_type, courier_unit_id: courier_unit_id).where(["effective_date <= ?", departure_date]).order("effective_date DESC").first
                            self.courier_price_id = cp.id
                          end
                
                          def check_min_shipment_per_pl
                            errors.add(:base, "Packing list must have at least one shipment") if packing_list_items.blank?
                          end
                
                          def courier_price_available                  
                            errors.add(:base, "Sorry, courier price is not available on #{departure_date.strftime("%d/%m/%Y")}") if departure_date.present? && attr_courier_id.present? && attr_courier_way_id.present? && courier_unit_id.present? && attr_city_id.present? && attr_courier_price_type.present? && CourierPrice.joins(courier_unit: :courier_way).select("1 AS one").where(city_id: attr_city_id, price_type: attr_courier_price_type, courier_unit_id: courier_unit_id).where(["courier_units.courier_way_id = ? AND courier_ways.courier_id = ? AND courier_prices.effective_date <= ?", attr_courier_way_id, attr_courier_id, departure_date]).blank?
                          end
                
                          def transaction_open(action = "not delete")
                            if departure_date.present?
                              if FiscalYear.joins(:fiscal_months).where(year: departure_date.year).where("fiscal_months.month = '#{Date::MONTHNAMES[departure_date.month]}' AND fiscal_months.status = 'Close'").select("1 AS one").present?
                                errors.add(:base, "Sorry, you can't perform this transaction")
                                throw :abort if action.eql?("delete")
                              end
                            end
                          end
                  
                          def city_available
                            errors.add(:attr_city_id, "does not exist!") if CourierPrice.joins(courier_unit: :courier_way).select("1 AS one").where(city_id: attr_city_id, courier_unit_id: courier_unit_id).where(["courier_units.courier_way_id = ? AND courier_ways.courier_id = ?", attr_courier_way_id, attr_courier_id]).blank?
                          end

                          def unit_available                  
                            errors.add(:courier_unit_id, "does not exist!") if CourierUnit.joins(courier_way: :courier).select("1 AS one").where(id: courier_unit_id).where(["couriers.id = ? AND courier_ways.id = ?", attr_courier_id, attr_courier_way_id]).blank?
                          end
              
                          def via_available
                            errors.add(:attr_courier_way_id, "does not exist!") if CourierWay.joins(:courier).select("1 AS one").where(id: attr_courier_way_id).where(["couriers.id = ?", attr_courier_id]).blank?
                          end
            
                          def record_not_deleted
                            if account_payable_courier_id.present?
                              errors.add(:base, "Sorry, you can't delete a record")
                              throw :abort
                            end
                          end
            
                          def delete_tracks
                            audits.destroy_all
                          end
          
                          def delete_courier_price_type
                            self.attr_courier_price_type = nil if attr_courier_id.present? && (@courier = Courier.select(:code, :status).find(attr_courier_id)).status.eql?("Internal")
                          end
            
                          def courier_available
                            errors.add(:attr_courier_id, "does not exist!") if @courier.blank?
                          end

                          def courier_price_type_available
                            errors.add(:attr_courier_price_type, "does not exist!") if CourierPrice.joins(courier_unit: :courier_way).select("1 AS one").where(city_id: attr_city_id, price_type: attr_courier_price_type, courier_unit_id: courier_unit_id).where(["courier_units.courier_way_id = ? AND courier_ways.courier_id = ?", attr_courier_way_id, attr_courier_id]).blank?
                          end
          
                          def generate_number
                            courier_code = @courier.code
                            current_month = departure_date.month.to_s.rjust(2, '0')
                            current_year = departure_date.strftime("%y").rjust(2, '0')
                            existed_numbers = PackingList.where("number LIKE '#{courier_code}#{current_month}#{current_year}PL%'").select(:number).order(:number)
                            if existed_numbers.blank?
                              new_number = "#{courier_code}#{current_month}#{current_year}PL0001"
                            else
                              if existed_numbers.length == 1
                                seq_number = existed_numbers[0].number.split("#{courier_code}#{current_month}#{current_year}PL").last
                                if seq_number.to_i > 1
                                  new_number = "#{courier_code}#{current_month}#{current_year}PL0001"
                                else
                                  new_number = "#{courier_code}#{current_month}#{current_year}PL#{seq_number.succ}"
                                end
                              else
                                last_seq_number = ""
                                existed_numbers.each_with_index do |existed_number, index|
                                  seq_number = existed_number.number.split("#{courier_code}#{current_month}#{current_year}PL").last
                                  if seq_number.to_i > 1 && index == 0
                                    new_number = "#{courier_code}#{current_month}#{current_year}PL0001"
                                    break                              
                                  elsif last_seq_number.eql?("")
                                    last_seq_number = seq_number
                                  elsif (seq_number.to_i - last_seq_number.to_i) > 1
                                    new_number = "#{courier_code}#{current_month}#{current_year}PL#{last_seq_number.succ}"
                                    break
                                  elsif index == existed_numbers.length - 1
                                    new_number = "#{courier_code}#{current_month}#{current_year}PL#{seq_number.succ}"
                                  else
                                    last_seq_number = seq_number
                                  end
                                end
                              end                        
                            end
                            self.number = new_number
                          end
            
                          def set_status
                            self.status = "Delivered"
                          end

                        end
