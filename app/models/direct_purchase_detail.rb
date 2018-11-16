class DirectPurchaseDetail < ApplicationRecord
  attr_accessor :product_id, :warehouse_id, :receiving_date

  belongs_to :direct_purchase_product
  belongs_to :size
  belongs_to :color
  
  has_one :received_purchase_order_item, dependent: :destroy
  
  accepts_nested_attributes_for :received_purchase_order_item
  
  validates :quantity, presence: true
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |dpd| dpd.quantity.present? }
    validate :item_available, on: :create
    validate :transaction_after_beginning_stock_added, if: proc{|dpd| dpd.receiving_date.present? && dpd.product_id.present? && dpd.warehouse_id.present? && Company.where(import_beginning_stock: true).select("1 AS one").present?}
    
      before_create :create_received_purchase_order_item
    
      private
      
      def transaction_after_beginning_stock_added
        listing_stock_transaction = ListingStockTransaction.select(:transaction_date).joins(listing_stock_product_detail: :listing_stock).where(transaction_type: "BS", :"listing_stock_product_details.color_id" => color_id, :"listing_stock_product_details.size_id" => size_id, :"listing_stocks.warehouse_id" => warehouse_id, :"listing_stocks.product_id" => product_id).first
        errors.add(:base, "Sorry, you can't receive article on #{receiving_date.to_date.strftime("%d/%m/%Y")}") if listing_stock_transaction.present? && listing_stock_transaction.transaction_date > receiving_date.to_date
      end
      
      def item_available
        errors.add(:base, "Not able to receive selected items") unless Product.select("1 AS one").joins(:product_colors, :product_details).where("products.id = #{product_id} AND product_colors.color_id = #{color_id} AND size_id = #{size_id}").present?
      end
    
      def create_received_purchase_order_item
        received_purchase_order_product_id = ReceivedPurchaseOrderProduct.select(:id).where(direct_purchase_product_id: direct_purchase_product_id).first.id
        self.attributes = self.attributes.merge(received_purchase_order_item_attributes: {
            received_purchase_order_product_id: received_purchase_order_product_id,
            quantity: quantity,
            direct_purchase_detail_id: id,
            is_it_direct_purchasing: true,
            product_id: product_id,
            warehouse_id: warehouse_id,
            receiving_date: receiving_date
          })
      end

    end
