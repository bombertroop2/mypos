class PriceList < ApplicationRecord
  attr_accessor :product_id, :size_id, :price_code_id, :user_is_adding_new_price,
    :user_is_updating_price, :user_is_deleting_from_child,
    :user_is_adding_price_from_cost_prices_page, :turn_off_date_validation, :editable_record

  audited associated_with: :product_detail, on: [:create, :update], only: [:effective_date, :price, :product_detail_id]

  belongs_to :product_detail
  
    
  attr_reader :cost
  
  before_validation :set_effective_date, if: proc {|price_list| price_list.user_is_adding_new_price}
  
    validates :price, numericality: {greater_than_or_equal_to: 1}, if: proc { |price_list| price_list.price.is_a?(Numeric) && price_list.price.present? }
      validates :effective_date, :price, :cost, presence: true        
      validates :product_detail_id, presence: true, if: proc {|price_list| !price_list.user_is_adding_new_price && !price_list.user_is_adding_price_from_cost_prices_page}
        validates :effective_date, date: {after_or_equal_to: Proc.new { Date.current }, message: 'must be after or equal to today' }, if: proc {|price_list| price_list.effective_date.present? && price_list.effective_date_changed? && !price_list.turn_off_date_validation}
          validates :effective_date, uniqueness: {scope: :product_detail_id}, if: proc {|price_list| price_list.effective_date.present?}
            validate :price_greater_or_equal_to_cost, if: proc {|price_list| price_list.price.present? && price_list.cost.present?}
          
              #            before_create :create_product_detail, if: proc {|price_list| price_list.product_detail_is_not_existed_yet && price_list.user_is_adding_new_price}
              #  before_destroy :get_parent
              before_destroy :prevent_user_delete_last_record, if: proc {|price_list| price_list.user_is_deleting_from_child}
                before_destroy :delete_tracks
                #  after_destroy :delete_parent
                
                def cost=(value)
                  attribute_will_change!(:cost)
                  @cost = value
                end
          
                private

                def delete_tracks
                  audits.destroy_all
                end

                def set_effective_date
                  # ambil dari effective date produk yang sudah ada
                  if product_id.present?
                    self.effective_date = Product.select(:id).where(id: product_id).first.active_cost.effective_date
                    self.turn_off_date_validation = true
                  else
                    # buat dengan tanggal hari ini
                    self.effective_date = Date.current
                  end
                end

                def price_greater_or_equal_to_cost
                  errors.add(:price, "must be greater than or equal to cost") if price < cost.to_f
                end

                def prevent_user_delete_last_record
                  if @product_detail.price_count.eql?(1) && @product_detail.product.product_details_count.eql?(1)
                    errors.add(:base, "Sorry, you can't delete a record")
                    throw :abort
                  end
                end            

        
            
              end
