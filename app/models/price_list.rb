class PriceList < ApplicationRecord
  belongs_to :product_detail
  
  attr_accessor :product_id, :size_id, :price_code_id, :user_is_adding_new_price,
    :user_is_updating_price, :user_is_deleting_from_child
  
  validates :price, numericality: {greater_than_or_equal_to: 1}, if: proc { |price_list| price_list.price.is_a?(Numeric) && price_list.price.present? }
    validates :product_id, :size_id, :price_code_id, presence: true, if: proc {|price_list| price_list.user_is_adding_new_price}
      validates :effective_date, :price, presence: true        
      validates :effective_date, date: {after_or_equal_to: Proc.new { Date.today }, message: 'must be after or equal to today' }, if: proc {|price_list| price_list.effective_date.present? && price_list.effective_date_changed?}
          
        before_create :create_product_detail, if: proc {|price_list| price_list.product_detail_is_not_existed_yet && price_list.user_is_adding_new_price}
          before_destroy :get_parent
          before_destroy :prevent_user_delete_last_record, if: proc {|price_list| price_list.user_is_deleting_from_child}
            after_destroy :delete_parent


          
          
            protected            
          
            def product_detail_is_not_existed_yet
              product_detail = ProductDetail.select(:id).where(size_id: size_id, product_id: product_id, price_code_id: price_code_id).first
              return true if product_detail.nil?
              self.product_detail_id = product_detail.id
              return false if product_detail.present?
            end
          
            private
            
            def prevent_user_delete_last_record
              if @product_detail.price_count.eql?(1) && @product_detail.product.product_details_count.eql?(1)
                errors.add(:base, "Sorry, you can't delete a record")
                return false
              end
            end            
          
            def get_parent
              @product_detail = self.product_detail
            end

            def delete_parent
              if @product_detail.price_count.eql?(0)
                @product_detail.destroy
              end
            end
        
            def create_product_detail
              product_detail = ProductDetail.new
              product_detail.size_id = size_id
              product_detail.product_id = product_id
              product_detail.price_code_id = price_code_id
              if product_detail.save
                self.product_detail_id = product_detail.id
              end
            end
            
          end
