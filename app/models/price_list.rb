class PriceList < ApplicationRecord
  attr_accessor :product_id, :size_id, :price_code_id, :user_is_adding_new_price,
    :user_is_updating_price, :user_is_deleting_from_child,
    :user_is_adding_price_from_cost_prices_page, :turn_off_date_validation, :editable_record,
    :attr_importing_data, :attr_insert_new_price

  audited associated_with: :product_detail, on: [:create, :update], only: [:effective_date, :price, :product_detail_id]

  belongs_to :product_detail
  has_many :sale_products, dependent: :restrict_with_error  
  has_many :consignment_sale_products, dependent: :restrict_with_error  
  has_many :shipment_product_items, dependent: :restrict_with_error  
  has_one :sale_product_relation, -> {select("1 AS one")}, class_name: "SaleProduct"
  has_one :consignment_sale_product_relation, -> {select("1 AS one")}, class_name: "ConsignmentSaleProduct"
    
  attr_reader :cost
  
  before_validation :set_effective_date, if: proc {|price_list| price_list.user_is_adding_new_price && !price_list.attr_importing_data}
  
    validates :price, numericality: {greater_than_or_equal_to: 1}, if: proc { |price_list| price_list.price.is_a?(Numeric) && price_list.price.present? }
      validates :price, numericality: {greater_than: :discount_event_amount, message: "must be greater than %{count} (Discount(Rp))"}, if: proc { |price_list| price_list.user_is_adding_price_from_cost_prices_page || (price_list.price_changed? && price_list.persisted?) }
        validates :effective_date, :price, presence: true        
        validates :cost, presence: true, unless: proc{|pl| pl.attr_importing_data}
          validates :product_detail_id, presence: true, if: proc {|price_list| !price_list.user_is_adding_new_price && !price_list.user_is_adding_price_from_cost_prices_page}
            validates :effective_date, date: {after_or_equal_to: Proc.new { Date.current }, message: 'must be after or equal to today' }, if: proc {|price_list| price_list.effective_date.present? && price_list.effective_date_changed? && !price_list.turn_off_date_validation && !price_list.attr_importing_data}
              validates :effective_date, uniqueness: {scope: :product_detail_id}, if: proc {|price_list| price_list.effective_date.present?}
                validate :price_greater_or_equal_to_cost, if: proc {|price_list| price_list.price.present? && price_list.cost.present? && !price_list.attr_importing_data && !price_list.additional_information.eql?("TH")}
                  validate :effective_date_not_changed, :price_not_changed, :product_detail_id_not_changed
                  validate :additional_information_available, if: proc{|pl| pl.user_is_adding_price_from_cost_prices_page || (pl.additional_information_changed? && pl.persisted? && pl.additional_information_was.present?)}
                    validate :price_less_than_previous_price, if: proc{|pl| (pl.additional_information_changed? || pl.price_changed?) && pl.additional_information.eql?("TH") && pl.effective_date.present? && pl.price.present?}
          
                      #            before_create :create_product_detail, if: proc {|price_list| price_list.product_detail_is_not_existed_yet && price_list.user_is_adding_new_price}
                      #  before_destroy :get_parent
                      before_destroy :prevent_user_delete_last_record, if: proc {|price_list| price_list.user_is_deleting_from_child}
                        before_destroy :prevent_user_delete_record_when_cashier_open, :delete_tracks
                        #  after_destroy :delete_parent
                
                        ADDITIONAL_INFORMATIONS = [
                          ["TH", "TH"],
                          ["NA", "NA"]
                        ]
  
                        def cost=(value)
                          attribute_will_change!(:cost)
                          @cost = value
                        end
          
                        private
                        
                        def price_less_than_previous_price
                          previous_price = if new_record?
                            PriceList.select(:price).where(["price_lists.effective_date <= ? AND product_detail_id = ?", effective_date, product_detail_id]).order(effective_date: :desc).first
                          else
                            PriceList.select(:price).where(["price_lists.effective_date <= ? AND product_detail_id = ? AND price_lists.id <> ?", effective_date, product_detail_id, id]).order(effective_date: :desc).first
                          end
                          errors.add(:price, "must be less than #{previous_price.price}") if previous_price.present? && previous_price.price > 0 && previous_price.price <= price
                        end
                  
                        def discount_event_amount
                          if product_detail_id.present? && effective_date.present?
                            product_det = ProductDetail.select(:product_id, :price_code_id).where(id: product_detail_id).first
                            event = Event.joins(event_warehouses: [:event_products, :warehouse]).select(:cash_discount).where(["start_date_time <= ? AND end_date_time >= ? AND event_products.product_id = ? AND select_different_products = ? AND (events.is_active = ? OR event_warehouses.is_active = ?) AND event_type = 'Discount(Rp)' AND warehouses.price_code_id = ? AND warehouses.is_active = ?", effective_date.end_of_day, effective_date.beginning_of_day, product_det.product_id, true, true, true, product_det.price_code_id, true]).order("events.created_at DESC").first
                            if event.present?
                              event.cash_discount
                            else
                              event = Event.joins(:event_general_products, event_warehouses: :warehouse).select(:cash_discount).where(["start_date_time <= ? AND end_date_time >= ? AND event_general_products.product_id = ? AND (select_different_products = ? OR select_different_products IS NULL) AND (events.is_active = ? OR event_warehouses.is_active = ?) AND event_type = 'Discount(Rp)' AND warehouses.price_code_id = ? AND warehouses.is_active = ?", effective_date.end_of_day, effective_date.beginning_of_day, product_det.product_id, false, true, true, product_det.price_code_id, true]).order("events.created_at DESC").first
                              if event.present?
                                event.cash_discount
                              else
                                0
                              end
                            end
                          else
                            0
                          end
                        end
                
                        def prevent_user_delete_record_when_cashier_open
                          current_date = Date.current
                          product_detail = ProductDetail.select(:product_id, :price_code_id).where(id: product_detail_id).first
                          cashier_opened = CashierOpening.joins(warehouse: [stock: :stock_products]).select("1 AS one").where(["closed_at IS NULL AND open_date = ? AND stock_products.product_id = ? AND warehouses.price_code_id = ? AND warehouses.is_active = ?", current_date, product_detail.product_id, product_detail.price_code_id, true]).present?
                          if current_date >= effective_date && cashier_opened
                            errors.add(:base, "Sorry, you can't delete a record, because sales is currently running")
                            throw :abort
                          end
                        end

                        def delete_tracks
                          audits.destroy_all
                        end

                        def set_effective_date
                          # ambil dari effective date produk yang sudah ada
                          if product_id.present?
                            self.effective_date = Product.select(:id).where(id: product_id).first.active_cost.effective_date
                            self.turn_off_date_validation = true
                          else
                            # buat dengan tanggal hari ini
                            self.effective_date = Date.current
                          end
                        end

                        def price_greater_or_equal_to_cost
                          errors.add(:price, "must be greater than or equal to cost") if price < cost.to_f
                        end

                        def prevent_user_delete_last_record
                          if @product_detail.price_count.eql?(1) && @product_detail.product.product_details_count.eql?(1)
                            errors.add(:base, "Sorry, you can't delete a record")
                            throw :abort
                          end
                        end            

                        def effective_date_not_changed
                          errors.add(:effective_date, "change is not allowed!") if effective_date_changed? && persisted?# && sale_product_relation.present?
                        end

                        def price_not_changed
                          if price_changed? && persisted?
                            if sale_product_relation.present? || consignment_sale_product_relation.present? || shipment_product_items.select("1 AS one").present?
                              errors.add(:price, "change is not allowed!")
                            else
                              current_date = Date.current
                              product_detail = ProductDetail.select(:product_id, :price_code_id).where(id: product_detail_id).first
                              cashier_opened = CashierOpening.joins(warehouse: [stock: :stock_products]).select("1 AS one").where(["closed_at IS NULL AND open_date = ? AND stock_products.product_id = ? AND warehouses.price_code_id = ? AND warehouses.is_active = ?", current_date, product_detail.product_id, product_detail.price_code_id, true]).present?
                              if current_date >= effective_date && cashier_opened
                                errors.add(:price, "change is not allowed because sales is currently running")
                              end
                            end
                          end
                        end

                        def product_detail_id_not_changed
                          errors.add(:product_detail_id, "change is not allowed!") if product_detail_id_changed? && persisted? && (sale_product_relation.present? || consignment_sale_product_relation.present? || shipment_product_items.select("1 AS one").present?)
                        end
        
                        def additional_information_available
                          PriceList::ADDITIONAL_INFORMATIONS.select{ |x| x[1] == additional_information }.first.first
                        rescue
                          errors.add(:additional_information, "does not exist!") if additional_information.present?
                        end
                      end
