class SalesReturn < ApplicationRecord
  attr_accessor :attr_receipt_number, :attr_cashier_id, :attr_spg_id
  belongs_to :returned_receipt, class_name: "Sale", foreign_key: "sale_id"
  has_one :sale
  has_many :sales_return_products, dependent: :destroy
  has_one :journal, :as => :transactionable

  accepts_nested_attributes_for :sales_return_products
  accepts_nested_attributes_for :sale

  before_validation :get_sale
  validate :is_new_sale_exist, :is_returned_product_exist
  before_create :generate_number, :calculate_total_return, :calculate_total_return_quantity
  after_create :pos_return_journal

  private

  def pos_return_journal
    coa = Coa.find_by_transaction_type('RET')
    gross_price = self.sale.sale_products.collect{|x| x.price_list.price.to_i }.sum
    discount = gross_price-self.total_return
    gross_after_discount = self.total_return
    ppn = gross_after_discount * 10 / 100
    nett = gross_after_discount - ppn
    warehouse = self.sale.cashier_opening.warehouse.id
    journal = self.build_journal(
        coa_id: coa.id,
        gross: gross_price.to_f,
        gross_after_discount: self.total_return.to_f,
        discount: discount.to_f,
        ppn: ppn.to_f,
        nett: nett.to_f,
        transaction_date: self.sale.transaction_time.to_date,
        activity: nil,
        warehouse_id: warehouses
      )
    journal.save
  end

  def calculate_total_return_quantity
    self.total_return_quantity = sales_return_products.length
  end

  def calculate_total_return
    self.total_return = SaleProduct.where(id: sales_return_products.map(&:sale_product_id)).sum(:total)
  end

  def get_sale
    @sale = Sale.
      joins(cashier_opening: [warehouse: :sales_promotion_girls]).
      joins("LEFT JOIN sales_returns ON sales_returns.sale_id = sales.id").
      select("sales.transaction_time, cashier_openings.warehouse_id, warehouses.code AS warehouse_code, sales.gift_event_id, sales_returns.sale_id AS returned_sale_id").
      where(["sales.id = ? AND warehouses.is_active = ?", sale_id, true]).
      where(:"sales_promotion_girls.id" => attr_spg_id).first
    transaction_time = @sale.transaction_time
    if ((Time.current - transaction_time) / 1.hour >= 74) || @sale.gift_event_id.present? || @sale.returned_sale_id.present?
      @sale = nil
    end
  end

  def is_returned_product_exist
    errors.add(:base, "Sales return must have at least one return product") if sales_return_products.blank?
  end

  def is_new_sale_exist
    errors.add(:base, "Sales return must have at least one receipt") if sale.blank?
  end

  def generate_number
    today = Date.current
    current_year = today.strftime("%y").rjust(2, '0')
    warehouse_code = @sale.warehouse_code.split("-").first.strip
    existed_numbers = SalesReturn.where("document_number LIKE '#{warehouse_code}RET#{current_year}%'").select(:document_number).order("id DESC")
    if existed_numbers.blank?
      new_number = "#{warehouse_code}RET#{current_year}00001"
    else
      seq_number = existed_numbers.first.document_number.split("#{warehouse_code}RET#{current_year}").last
      new_number = "#{warehouse_code}RET#{current_year}#{seq_number.succ}"
    end
    self.document_number = new_number
  end
end
