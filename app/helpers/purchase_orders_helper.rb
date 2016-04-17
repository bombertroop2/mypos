module PurchaseOrdersHelper
  def selected_product_collection
    return params[:product_collections] if params[:product_collections]
    return @products.map(&:id) if @products.present?
  end
  
  def get_or_build_received_po_object(po_product, color)
    received_purchase_order_detail = po_product.received_purchase_orders.select{|rpo| rpo.color.eql?(color)}.first
    unless received_purchase_order_detail
      received_purchase_order_detail = po_product.received_purchase_orders.build(color: color)
    end
    received_purchase_order_detail
  end
  
  def get_or_build_purchase_order_product_object(purchase_order, product)
    purchase_order_product_detail = purchase_order.purchase_order_products.select{|pop| pop.product_id.eql?(product.id)}.first
    unless purchase_order_product_detail
      purchase_order_product_detail = purchase_order.purchase_order_products.build(product_id: product.id)
    end
    purchase_order_product_detail
  end
  
  def get_or_build_purchase_order_detail_object(purchase_order_product, size, color)    
    purchase_order_detail_detail = purchase_order_product.purchase_order_details.select{|pod| pod.size.eql?(size) and pod.color.eql?(color)}.first
    unless purchase_order_detail_detail
      purchase_order_detail_detail = purchase_order_product.purchase_order_details.build(size: size, color: color)
    end
    purchase_order_detail_detail
  end
  
  def create_product_array_variable_name(purchase_order_product, product)
    if purchase_order_product.new_record?
      "purchase_order[purchase_order_products_attributes][#{Time.now.to_i.to_s+product.id.to_s}]"
    else
      "purchase_order[purchase_order_products_attributes][#{purchase_order_product.id}]"
    end
  end
  
  def create_product_detail_array_variable_name(purchase_order_detail, index, purchase_order_product_array_index)    
    if purchase_order_detail.new_record?
      "#{purchase_order_product_array_index}[purchase_order_details_attributes][#{Time.now.to_i.to_s+index.to_s}]"
    else
      "#{purchase_order_product_array_index}[purchase_order_details_attributes][]"
    end
  end
  
  def create_received_purchase_order_array_variable_name(received_po_detail, purchase_order_product, color)
    "purchase_order[purchase_order_products_attributes][#{purchase_order_product.id}][received_purchase_orders_attributes][#{color.id}]"
  end
  
  def get_net_order_value(purchase_order)
    if purchase_order.is_taxable_entrepreneur && purchase_order.value_added_tax.eql?("exclude")
      net_order_value = purchase_order.order_value
    else
      #      if purchase_order.first_discount && purchase_order.second_discount.blank?
      purchase_order.order_value - purchase_order.order_value * 0.10
    end
  end
  
  def get_gross_order_value(purchase_order)
    if purchase_order.is_taxable_entrepreneur && purchase_order.value_added_tax.eql?("exclude")
      if purchase_order.first_discount && purchase_order.second_discount.blank?
        net_order_value = purchase_order.order_value - purchase_order.order_value * (purchase_order.first_discount.to_f / 100)
        gross_order_value = net_order_value + net_order_value * 0.10
      elsif purchase_order.first_discount && purchase_order.second_discount
        if purchase_order.is_additional_disc_from_net
          net_order_value_from_first_disc = purchase_order.order_value - purchase_order.order_value * (purchase_order.first_discount.to_f / 100)
          net_order_value = net_order_value_from_first_disc - net_order_value_from_first_disc * (purchase_order.second_discount.to_f / 100)
        else
          net_order_value = purchase_order.order_value - purchase_order.order_value * ((purchase_order.first_discount.to_f + purchase_order.second_discount.to_f) / 100)
        end        
        gross_order_value = net_order_value + net_order_value * 0.10
      elsif purchase_order.price_discount
        net_order_value = purchase_order.order_value - (purchase_order.order_value - purchase_order.price_discount)
        gross_order_value = net_order_value + net_order_value * 0.10
      else
        gross_order_value = purchase_order.order_value + purchase_order.order_value * 0.10
      end    
    else
      gross_order_value = purchase_order.order_value
    end
    gross_order_value
  end
  
  def value_after_discount(purchase_order)
    value_after_first_discount = purchase_order.order_value - purchase_order.order_value * (purchase_order.first_discount.to_f / 100)
    value_after_second_discount = if purchase_order.is_additional_disc_from_net
      value_after_first_discount - value_after_first_discount * (purchase_order.second_discount.to_f / 100)
    elsif purchase_order.second_discount.present?
      purchase_order.order_value - purchase_order.order_value * ((purchase_order.first_discount.to_f + purchase_order.second_discount.to_f) / 100)
    end
    value_after_money_discount = purchase_order.order_value - purchase_order.price_discount rescue nil
    return value_after_money_discount || value_after_second_discount || value_after_first_discount
  end
  
  def value_after_ppn(purchase_order)
    if purchase_order.value_added_tax.eql?("exclude")
      value_after_discount(purchase_order) + get_vat_in_money(purchase_order)
    else
      value_after_discount(purchase_order)
    end
  end
  
  def get_second_discount_in_money(purchase_order)
    if purchase_order.is_additional_disc_from_net
      value_from_first_discount = purchase_order.order_value - purchase_order.order_value * (purchase_order.first_discount.to_f / 100)
      value_from_first_discount * (purchase_order.second_discount.to_f / 100)
    else
      purchase_order.order_value * (purchase_order.second_discount.to_f / 100)
    end
  end
  
  def get_vat_in_money(purchase_order)
    value_after_discount(purchase_order) * 0.1
  end
end
