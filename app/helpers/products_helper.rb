module ProductsHelper
  def selected_size_group
    return params[:size_groups] if params[:size_groups]
    return @product.sizes.first.size_group.id if @product.sizes.first
  end
  
  def get_or_build_product_price_code_object(product, price_code)
    product_price_code = product.product_price_codes.select{|ppc| ppc.price_code.eql?(price_code)}.first
    unless product_price_code
      product_price_code = product.product_price_codes.build(price_code: price_code)
    end
    product_price_code
  end
  
  def create_price_code_array_variable_name(product_price_code, price_code)
    if product_price_code.new_record?
      "product[product_price_codes_attributes][#{Time.now.to_i.to_s+price_code.id.to_s}]"
    else
      "product[product_price_codes_attributes][#{product_price_code.id}]"
    end
  end
end
