class PurchaseOrderProduct < ActiveRecord::Base
  belongs_to :purchase_order
  belongs_to :product
  belongs_to :warehouse
  
  has_many :purchase_order_details, dependent: :destroy
  has_many :received_purchase_orders, dependent: :destroy
  has_many :sizes, -> { group("sizes.id").order(:size) }, through: :purchase_order_details
  has_many :colors, -> { group("common_fields.id").order(:code) }, through: :purchase_order_details


  validates :product_id, uniqueness: {scope: :purchase_order_id}, if: proc { |pop| pop.product_id.present? }
    validates :product_id, presence: true
    validates :purchase_order_details, :length => { :minimum => 1 }

    accepts_nested_attributes_for :purchase_order_details, allow_destroy: true,
      reject_if: lambda { |a| a[:quantity].blank? }

    accepts_nested_attributes_for :received_purchase_orders, allow_destroy: true,
      reject_if: lambda { |a| a[:is_received].eql?("0") }
  end
