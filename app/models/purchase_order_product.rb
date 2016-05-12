class PurchaseOrderProduct < ActiveRecord::Base
  attr_accessor :purchase_order_date
  
  belongs_to :purchase_order
  belongs_to :product
  belongs_to :cost_list
  
  has_many :purchase_order_details, dependent: :destroy
  has_many :sizes, -> { group("sizes.id").order(:size) }, through: :purchase_order_details
  has_many :colors, -> { group("common_fields.id").order(:code) }, through: :purchase_order_details
  
  validate :existing_cost, if: proc {|pop| pop.purchase_order_date.present?}

  before_create :set_active_cost

  accepts_nested_attributes_for :purchase_order_details, allow_destroy: true, reject_if: proc { |attributes| attributes[:quantity].blank? and attributes[:id].blank? }

  def total_quantity
    purchase_order_details.sum :quantity
  end
  
  def total_cost
    purchase_order_details.sum(:quantity) * cost_list.cost
  end
  
  private
  
  def existing_cost
    errors.add(:base, "Sorry, there is no active cost for product #{product.code} on #{purchase_order_date}") if (@cost = active_cost).blank?
  end
  
  def active_cost
    cost_lists = product.cost_lists.select(:id, :cost, :effective_date).order("effective_date DESC")
    if cost_lists.size == 1
      cost_list = cost_lists.first
      if purchase_order_date.to_date >= cost_list.effective_date
        return cost_list
      end
    else
      cost_lists.each do |cost_list|
        if purchase_order_date.to_date >= cost_list.effective_date
          return cost_list
        end
      end
    end
  end
  
  def set_active_cost
    self.cost_list_id = @cost.id
  end
end
