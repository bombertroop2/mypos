class SaleProduct < ApplicationRecord
  attr_accessor :sales_promotion_girl_id, :event_type, :effective_price,
    :first_plus_discount, :second_plus_discount, :cash_discount, :attr_returned_sale_id, :attr_returning_sale

  belongs_to :sale
  belongs_to :product_barcode
  belongs_to :free_product, class_name: "StockDetail", foreign_key: :free_product_id
  belongs_to :price_list
  belongs_to :event
  belongs_to :returned_product, class_name: "SaleProduct", foreign_key: :returned_product_id

  # hapus event_id apabila event gift, cukup di parent Sale
  before_validation :add_quantity, :update_total
  before_validation :remove_event_id, if: proc{|sp| sp.event_type.eql?("Gift")}

    validates :quantity, presence: true
    validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |sp| sp.quantity.present? }
      validates :quantity, numericality: {less_than_or_equal_to: :stock_quantity, only_integer: true}, if: proc { |sp| sp.quantity.present? }
        validates :free_product_id, presence: true, if: proc{|sp| sp.event_id.present? && sp.event_type.eql?("Buy 1 Get 1 Free")}
          validates :price_list_id, presence: true#, unless: proc{|sp| sp.event_type.eql?("Special Price")}
          validates :total, numericality: {greater_than: 0}
          validate :returned_product_exist, if: proc {|sp| sp.attr_returning_sale}

            after_create :update_stock

            def point_of_sale_journal_details
              journal = self.sale.journal
              if event_id.present?
                if self.event.event_type.eql?("Discount(%)") || self.event.event_type.eql?("Discount(Rp)") || self.event.event_type.eql?("Special Price")
                  product = self.product_barcode.product_color.product.id
                  gross_price = self.price_list.price.to_i
                  if event_id.present? && self.event.event_type.eql?("Discount(%)") && event.first_plus_discount.present? && event.second_plus_discount.present?
                    first_discount = gross_price * event.first_plus_discount/100
                    second_discount = (gross_price - first_discount) * event.second_plus_discount/100
                    discount = first_discount + second_discount
                  elsif event_id.present? && self.event.event_type.eql?("Discount(%)") && first_plus_discount.present?
                    discount = gross_price * event.first_plus_discount/100
                  elsif event_id.present? && self.event.event_type.eql?("Discount(Rp)") && cash_discount.present?
                    discount = event.cash_discount
                  elsif self.event.event_type.eql?("Special Price")
                    discount = gross_price - event.special_price
                  end
                  gross_after_discount = gross_price - discount
                  ppn = gross_after_discount * 10 / 100
                  nett = gross_after_discount - ppn
                  journal.journal_discount_details.create(
                    product_id: product,
                    gross: gross_price,
                    gross_after_discount: gross_after_discount,
                    discount: discount,
                    ppn: ppn,
                    nett: nett
                    )
                elsif self.free_product_id.present?
                  product_id = self.free_product.stock_product.product_id
                  pd = ProductDetail.where(product_id: product_id, size_id: self.free_product.size_id, price_code_id: self.sale.cashier_opening.warehouse.price_code_id).first
                  gross_price = pd.active_price.price.to_i
                  discount = pd.active_price.price.to_i
                  gross_after_discount = gross_price - discount
                  ppn = gross_after_discount * 10 / 100
                  nett = gross_after_discount - ppn
                  journal.journal_detail_bogos.create(
                    product_id: product_id,
                    gross: gross_price,
                    gross_after_discount: gross_after_discount,
                    discount: discount,
                    ppn: ppn,
                    nett: nett
                    )
                end
              else
                product = self.product_barcode.product_color.product.id
                gross_price = self.price_list.price.to_i
                discount = 0
                gross_after_discount = gross_price - discount
                ppn = gross_after_discount * 10 / 100
                nett = gross_after_discount - ppn
                journal.journal_detail_non_events.create(
                  product_id: product,
                  gross: gross_price,
                  gross_after_discount: gross_after_discount,
                  discount: discount,
                  ppn: ppn,
                  nett: nett
                  )
              end
            end

            private

            def returned_product_exist
              returned_product = SaleProduct.
                joins(:sale).
                where(id: returned_product_id, :"sales.id" => attr_returned_sale_id).
                select("1 AS one").
                first
              errors.add(:returned_product_id, "doesn't exist") if returned_product.blank?
            end

            def add_quantity
              self.quantity = 1
            end

            def remove_event_id
              self.event_id = nil
            end

            def update_total
              if event_id.blank? || (event_id.present? && (event_type.eql?("Buy 1 Get 1 Free") || event_type.eql?("Special Price") || event_type.eql?("Gift")))
                self.total = quantity * effective_price.to_f
              elsif event_id.present? && event_type.eql?("Discount(%)")
                if first_plus_discount.present? && second_plus_discount.present?
                  first_discounted_subtotal = effective_price.to_f * quantity - effective_price.to_f * quantity * first_plus_discount.to_f / 100
                  self.total = first_discounted_subtotal - first_discounted_subtotal * second_plus_discount.to_f / 100
                elsif first_plus_discount.present?
                  self.total = effective_price.to_f * quantity - effective_price.to_f * quantity * first_plus_discount.to_f / 100
                end
              elsif event_id.present? && event_type.eql?("Discount(Rp)")
                self.total = effective_price.to_f * quantity - cash_discount.to_f
              end
            end

            def stock_quantity
              @sd = StockDetail.joins(:size, stock_product: [product: [product_colors: :product_barcodes], stock: [warehouse: :sales_promotion_girls]]).
                where(:"sales_promotion_girls.id" => sales_promotion_girl_id, :"product_barcodes.id" => product_barcode_id, :"warehouses.is_active" => true).
                where("stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
                select(:id, :quantity, :booked_quantity, :barcode).first
              @barcode = @sd.barcode
              @sd.quantity.to_i - @sd.booked_quantity.to_i
            end

            def update_stock
              raise_error = false
              @sd.with_lock do
                if @sd.quantity.to_i - @sd.booked_quantity.to_i >= quantity
                  @sd.quantity -= quantity
                  @sd.save
                else
                  raise_error = true
                end
              end
              if raise_error
                raise "Sorry, product #{@barcode} is temporarily out of stock"
              else
                if event_id.present? && event_type.eql?("Buy 1 Get 1 Free") && free_product_id.present?
                  free_product_stock = StockDetail.where(id: free_product_id).select(:id, :quantity, :booked_quantity).first
                  free_product_stock.with_lock do
                    if free_product_stock.quantity.to_i - free_product_stock.booked_quantity.to_i >= quantity
                      free_product_stock.quantity -= quantity
                      free_product_stock.save
                    else
                      raise_error = true
                    end
                  end
                  raise "Sorry, free product from product #{@barcode} is temporarily out of stock" if raise_error
                end
              end
            end
          end
