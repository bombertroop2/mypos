class DirectPurchaseProduct < ApplicationRecord
  attr_accessor :receiving_date, :dp_cost, :prdct_code, :prdct_name

  belongs_to :direct_purchase
  belongs_to :product
  belongs_to :cost_list
  
  has_one :received_purchase_order_product, dependent: :destroy
  has_many :direct_purchase_details, dependent: :destroy
  has_many :sizes, -> { group("sizes.id").order(:size_order) }, through: :direct_purchase_details
  has_many :colors, -> { group("common_fields.id").order(:code) }, through: :direct_purchase_details

  
  validate :should_has_details, on: :create
  validate :existing_cost, on: :create
  #    validate :vendor_products, if: proc {|pop| pop.vendor_id.present?}

  accepts_nested_attributes_for :received_purchase_order_product
  accepts_nested_attributes_for :direct_purchase_details, reject_if: proc { |attributes| attributes[:quantity].blank? }

  before_create :create_received_purchase_order_product

  
  def active_cost(receiving_date)
    cost_lists = product.cost_lists.select(:id, :cost, :effective_date)
    #        if cost_lists.size == 1
    #          cost_list = cost_lists.first
    #          if receiving_date >= cost_list.effective_date
    #            return cost_list
    #          end
    #        else
    cost_lists.each_with_index do |cost_list, index|
      if receiving_date >= cost_list.effective_date
        return cost_list
      end
    end
      
    return nil
    #        end
  end
  
  private
    
      
  #      def vendor_products
  #        vendor = Vendor.select(:id, :name).where(id: vendor_id).limit(1).first
  #        is_vendor_having_product = vendor.products.where(id: product_id).select("1 AS one").present?
  #        errors.add(:base, "This product is not available on #{vendor.name}") unless is_vendor_having_product
  #      end
    
  def existing_cost
    errors.add(:base, "Sorry, there is no active cost for product #{prdct_code} on #{receiving_date}") if cost_list_id.nil? && direct_purchase_details.present?
  end
  
  def should_has_details    
    errors.add(:base, "Please insert at least one piece per product!") if direct_purchase_details.blank?
  end
  
  def create_received_purchase_order_product
    received_purchase_order_id = ReceivedPurchaseOrder.select(:id).where(direct_purchase_id: direct_purchase_id).first.id
    self.attributes = self.attributes.merge(received_purchase_order_product_attributes: {
        received_purchase_order_id: received_purchase_order_id,
        direct_purchase_product_id: id
      })
  end
end
