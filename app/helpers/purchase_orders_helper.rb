module PurchaseOrdersHelper
  def selected_product_collection
    return params[:product_collections] if params[:product_collections]
    return @products.map(&:id) if @products.present?
  end
  
  def check_empty_column(colors, has_color_at_least_one_product)
    color_code = ""
    colors.each do |color|
      if has_color_at_least_one_product.select{|k, v| v[color.code] == true }.blank?
        color_code = color.code
        break
      end
    end
    color_code
  end
end
