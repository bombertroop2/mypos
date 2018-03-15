module SalesHelper
  def get_event_value(store_event, row_index, free_product=nil)
    unless free_product.nil?
      return "BOGO: <span id='bogo_product_detail_container_#{row_index}'>#{free_product.name}/#{free_product.color_name}/#{free_product.product_size}</span><br /><button type='button' class='btn btn-primary btn_add_bogo_product' id='btn_add_bogo_product_#{row_index}'><span class='glyphicon glyphicon-edit'></span> Edit</button>".html_safe if store_event["event_type"].eql?("Buy 1 Get 1 Free")
    else
      return "BOGO: <span id='bogo_product_detail_container_#{row_index}'></span><br /><button type='button' class='btn btn-primary btn_add_bogo_product' id='btn_add_bogo_product_#{row_index}'><span class='glyphicon glyphicon-plus'></span> Add</button>".html_safe if store_event["event_type"].eql?("Buy 1 Get 1 Free")
    end
    return "#{store_event["first_plus_discount"]}% + #{store_event["second_plus_discount"]}%" if store_event["first_plus_discount"].present? && store_event["second_plus_discount"].present?
    return "#{store_event["first_plus_discount"]}%" if store_event["first_plus_discount"].present?
    return "#{number_to_currency(store_event["cash_discount"], :separator => ",", :delimiter => ".", :unit => "Rp", :precision => 2)}" if store_event["cash_discount"].present?
    return "Special price: #{number_to_currency(store_event["special_price"], :separator => ",", :delimiter => ".", :unit => "Rp", :precision => 2)}" if store_event["special_price"].present?
  end  
end
