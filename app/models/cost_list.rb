class CostList < ActiveRecord::Base
  belongs_to :product
  
  has_many :purchase_order_products
  
  validates :cost, :effective_date, presence: true
  validates :product_id, presence: true, unless: proc{|cost_list| cost_list.is_user_creating_product}
    validates :cost, numericality: true, if: proc { |cost_list| cost_list.cost.present? }
      validates :cost, numericality: {greater_than: 0}, if: proc { |cost_list| cost_list.cost.is_a?(Numeric) }
        validates :effective_date, date: {after_or_equal_to: Proc.new { Date.today }, message: 'must be after or equal to today' }, if: proc {|cost_list| cost_list.effective_date.present? && cost_list.effective_date_changed?}
          
          attr_accessor :is_user_creating_product, :user_is_deleting_from_child
          
          before_destroy :prevent_user_delete_last_record, if: proc {|cost_list| cost_list.user_is_deleting_from_child}
          
          private
          
          def prevent_user_delete_last_record
            if product.cost_count.eql?(1)
              errors.add(:base, "Sorry, you can't delete a record")
              return false
            end
          end
          
        end
