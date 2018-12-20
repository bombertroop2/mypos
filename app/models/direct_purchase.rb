class DirectPurchase < ApplicationRecord
  include Accounting::TransactionCashIn

  audited on: :create

  belongs_to :vendor
  belongs_to :warehouse

  has_many :account_payable_purchases, as: :purchase, dependent: :restrict_with_error
  has_one :received_purchase_order, dependent: :destroy
  has_many :direct_purchase_products, dependent: :destroy
  has_many :purchase_returns

  accepts_nested_attributes_for :direct_purchase_products
  accepts_nested_attributes_for :received_purchase_order

  validates :vendor_id, :warehouse_id, :receiving_date, presence: true
  validates :first_discount, numericality: {greater_than: 0, less_than_or_equal_to: 100}, if: proc {|dp| dp.first_discount.present?}
    validate :prevent_adding_second_discount_if_first_discount_is_100, if: proc {|dp| dp.second_discount.present?}
      validates :first_discount, presence: true, if: proc {|dp| dp.second_discount.present?}
        validate :prevent_adding_second_discount_if_total_discount_greater_than_100, if: proc {|dp| dp.second_discount.present? && !dp.is_additional_disc_from_net}
          validates :second_discount, numericality: {greater_than: 0, less_than_or_equal_to: 100}, if: proc {|dp| dp.second_discount.present?}
            validate :should_has_products
            validates :receiving_date, date: {before_or_equal_to: Proc.new { Date.current }, message: 'must be before or equal to today' }, if: proc {|dp| dp.receiving_date.present?}
              validate :vendor_exist, if: proc{|dp| dp.vendor_id.present?}
                validate :warehouse_exist, if: proc{|dp| dp.warehouse_id.present?}
                  validate :transaction_open, if: proc{|dp| dp.receiving_date.present?}

                    before_create :set_vat_and_entrepreneur_status, :set_nil_to_is_additional_disc_from_net, :calculate_total_quantity, :set_receiving_date_to_receiving_purchase_order

                    def quantity_received
                      quantity = 0
                      direct_purchase_products.select(:id).each do |dpp|
                        quantity += dpp.direct_purchase_details.sum(:quantity)
                      end
                      quantity
                    end

                    def receiving_value
                      value = 0
                      direct_purchase_products.select(:id).each do |dpp|
                        value += dpp.direct_purchase_details.sum(:total_unit_price)
                      end
                      value
                    end

                    private

                    def transaction_open
                      errors.add(:base, "Sorry, you can't perform this transaction") if FiscalYear.joins(:fiscal_months).where(year: receiving_date.year).where("fiscal_months.month = '#{Date::MONTHNAMES[receiving_date.month]}' AND fiscal_months.status = 'Close'").select("1 AS one").present?
                    end

                    def vendor_exist
                      errors.add(:vendor_id, "does not exist!") unless (@vendor = Vendor.select(:value_added_tax, :is_taxable_entrepreneur).where(id: vendor_id).first).present?
                    end

                    def warehouse_exist
                      errors.add(:warehouse_id, "does not exist!") if Warehouse.select("1 AS one").where(id: warehouse_id, is_active: true).where("warehouse_type = 'central'").blank?
                    end

                    def set_receiving_date_to_receiving_purchase_order
                      received_purchase_order.receiving_date = receiving_date
                    end

                    def calculate_total_quantity
                      received_purchase_order.quantity = 0
                      direct_purchase_products.each do |direct_purchase_product|
                        received_purchase_order.quantity += direct_purchase_product.direct_purchase_details.map(&:quantity).sum
                      end
                    end

                    def should_has_products
                      errors.add(:base, "Please select at least one product!") if direct_purchase_products.blank?
                    end


                    def set_nil_to_is_additional_disc_from_net
                      self.is_additional_disc_from_net = nil if second_discount.blank?
                    end

                    def prevent_adding_second_discount_if_total_discount_greater_than_100
                      errors.add(:second_discount, "can't be added, because total discount (1st discount + 2nd discount) is greater than 100%") if (first_discount + second_discount) > 100 && second_discount <= 100
                    end

                    def prevent_adding_second_discount_if_first_discount_is_100
                      errors.add(:second_discount, "can't be added, because first discount is already 100%") if first_discount == 100
                    end

                    def set_vat_and_entrepreneur_status
                      self.vat_type = @vendor.value_added_tax
                      self.is_taxable_entrepreneur = @vendor.is_taxable_entrepreneur
                      return true
                    end
                  end
