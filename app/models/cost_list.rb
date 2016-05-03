class CostList < ActiveRecord::Base
  belongs_to :product
  
  has_many :purchase_order_products
  
  validates :cost, :effective_date, presence: true
  validates :product_id, presence: true, unless: proc{|cost_list| cost_list.is_user_creating_product}
    validates :cost, numericality: true, if: proc { |cost_list| cost_list.cost.present? }
      validates :cost, numericality: {greater_than: 0}, if: proc { |cost_list| cost_list.cost.is_a?(Numeric) }
        validates :effective_date, date: {after_or_equal_to: Proc.new { Date.today }, message: 'must be after or equal to today' }, if: proc {|cost_list| cost_list.effective_date.present? && cost_list.effective_date_changed?}
          validates :effective_date, date: {after: proc {|cost_list| cost_list.latest_cost_effective_date }, message: 'must be after latest effective date' }, if: proc {|cost_list| cost_list.effective_date.present? && cost_list.effective_date >= Date.today && cost_list.product_id.present? && cost_list.effective_date_changed?}
          
            attr_accessor :is_user_creating_product
          
            def latest_cost_effective_date
              cost_lists = CostList.select(:effective_date).where(product_id: product_id).order("effective_date DESC")
              if cost_lists.size > 1
                CostList.select(:effective_date).where(product_id: product_id).order("effective_date DESC").first.effective_date
              else
                1.day.ago
              end
            end
          end
