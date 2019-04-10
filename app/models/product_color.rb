class ProductColor < ApplicationRecord
  audited associated_with: :product, on: [:create, :update]

  belongs_to :product
  belongs_to :color
  has_many :product_barcodes, dependent: :destroy
  
  attr_accessor :code, :name, :selected_color_id, :attr_importing_data
  
  validates :color_id, presence: true
  validate :color_available
  validate :color_not_added, on: :create, unless: proc{|pc| pc.attr_importing_data}
  
    before_destroy :prevent_deleting_if_po_is_created,
      :prevent_deleting_if_direct_purchase_is_created,
      :prevent_deleting_if_order_booking_is_created, :delete_tracks,
      :prevent_deleting_if_stock_mutation_is_created
  
    after_create :create_barcode, unless: proc{|pc| pc.attr_importing_data}

      private
  
      def create_barcode
        first_three_digits_company_code = Company.order(:id).pluck(:code).first.first(3)
        product.product_details.select(:size_id).distinct.each do |product_detail|
          pb = ProductBarcode.where(["barcode LIKE ?", "#{first_three_digits_company_code}1S%"]).select(:barcode).order("barcode DESC").first
          barcode = if pb.present?
            "#{first_three_digits_company_code}1S#{pb.barcode.split("#{first_three_digits_company_code}1S")[1].succ}"
          else
            "#{first_three_digits_company_code}1S00001"
          end
          product_barcode = product_barcodes.build size_id: product_detail.size_id, barcode: barcode
          product_barcode.save
        end
      end
  
      def delete_tracks
        audits.destroy_all
      end

      # apabila sudah ada relasi dengan table lain maka tidak dapat tambah color
      def color_not_added
        errors.add(:base, "Color addition is not allowed!") if new_record? && product && (product.order_booking_product_relation.present? || product.stock_product_relation.present? || product.purchase_order_relation.present? || product.direct_purchase_product_relation.present? || product.cost_lists.select(:id).count > 1 || product.stock_mutation_product_relation.present?)
      end

  
      def color_available
        errors.add(:color_id, "does not exist!") if color_id.present? && Color.where(id: color_id).select("1 AS one").blank?
      end
  
      def prevent_deleting_if_po_is_created    
        throw :abort if PurchaseOrderDetail.joins(purchase_order_product: :purchase_order).select("1 AS one").where(["color_id = ? AND purchase_order_products.product_id = ?", color_id, product_id]).first.present?
      end

      def prevent_deleting_if_direct_purchase_is_created        
        throw :abort if DirectPurchaseDetail.joins(:direct_purchase_product).select("1 AS one").where(["color_id = ? AND product_id = ?", color_id, product_id]).first.present?
      end
  
      def prevent_deleting_if_order_booking_is_created
        throw :abort if OrderBookingProduct.joins(:order_booking_product_items).select("1 AS one").where(["color_id = ? AND product_id = ?", color_id, product_id]).first.present?
      end

      def prevent_deleting_if_stock_mutation_is_created
        throw :abort if product.stock_mutation_product_relation.present?
      end
    end
