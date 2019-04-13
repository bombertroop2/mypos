class SalesReturn < ApplicationRecord
  attr_accessor :attr_receipt_number, :attr_cashier_id, :attr_spg_id, :attr_sale_member_product_event, :attr_sale_member_discount
  belongs_to :returned_receipt, class_name: "Sale", foreign_key: "sale_id"
  has_one :sale
  has_many :sales_return_products, dependent: :destroy

  accepts_nested_attributes_for :sales_return_products
  accepts_nested_attributes_for :sale
  
  before_validation :get_sale 
  validate :is_cashier_opened, :is_new_sale_exist, :is_returned_product_exist, :attr_sale_member_product_event_valid, :attr_sale_member_discount_valid
  before_create :generate_number, :calculate_total_return, :calculate_total_return_quantity
  
  private
  
  def attr_sale_member_discount_valid
    errors.add(:base, "Member discount is not valid") if @sale.sale_member_discount != attr_sale_member_discount
  end
  
  def attr_sale_member_product_event_valid
    errors.add(:base, "attr_sale_member_product_event is not valid") if @sale.sale_member_product_event != attr_sale_member_product_event
  end
  
  def is_cashier_opened
    if @sale.present?
      co = CashierOpening.joins(:warehouse).select(:id, :warehouse_id).where(warehouse_id: @sale.cashier_opening_warehouse_id).where("closed_at IS NULL").where(["open_date = ? AND warehouses.is_active = ?", Date.current, true]).where("opened_by = #{attr_cashier_id}").first
      errors.add(:base, "Please open the cashier first") if co.blank?
    end
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
      select("sales.transaction_time, cashier_openings.warehouse_id AS cashier_opening_warehouse_id, warehouses.code AS warehouse_code, sales.gift_event_id, sales_returns.sale_id AS returned_sale_id, sales.member_product_event AS sale_member_product_event, sales.member_discount AS sale_member_discount").
      where(["sales.id = ? AND warehouses.is_active = ?", sale_id, true]).
      where(:"sales_promotion_girls.id" => attr_spg_id).first
    transaction_time = @sale.transaction_time
    if Time.current > (transaction_time + 3.days).end_of_day || @sale.gift_event_id.present? || @sale.returned_sale_id.present?
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
