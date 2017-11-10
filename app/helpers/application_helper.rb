module ApplicationHelper    
  def remove_empty_space_from_phone_number(number)
    number.gsub("_", "") rescue nil
  end
  
  def control_group_error(model, field_name)
    " has-error" if model && model.errors[field_name].present?
  end

  def error_help_text(model, field_name)
    "<span class='help-block'>#{model.errors[field_name].join(", ")}</span>".html_safe if model && model.errors[field_name].present?
  end
  
  def product_menu_active?
    return true if can? :read, Brand
    return true if can? :read, GoodsType
    return true if can? :read, Model
    return true if can? :read, Color
    return true if can? :read, SizeGroup
    return true if can? :read, Product
  end
  
  def price_control_menu_active?
    return true if can? :read, PriceCode
    return true if can? :read, CostList
  end
  
  def warehouse_control_menu_active?
    return true if can? :read, SalesPromotionGirl
    return true if can? :read, Supervisor
    return true if can? :read, Warehouse
    return true if can? :read, Region
  end
  
  def purchase_order_menu_active?
    return true if can? :read, Vendor
    return true if can? :read, PurchaseOrder
    return true if can? :read, ReceivedPurchaseOrder
    return true if can? :read, PurchaseReturn
    return true if can? :read, AccountPayable
  end
  
  def booking_control_menu_active?
    return true if can? :read, OrderBooking
    return true if can? :read_action, Shipment
    return true if can? :read, Courier
  end
  
  def inventory_receipt_menu_active?
    return true if can? :read_action, Shipment
    return true if can? :read_store_to_store_inventory_receipts, StockMutation
    return true if can? :read_store_to_warehouse_inventory_receipts, StockMutation
  end
  
  def stock_mutation_menu_active?
    return true if can? :read_store_to_store_mutations, StockMutation
    return true if can? :read_store_to_warehouse_mutations, StockMutation
  end
  
  def report_menu_active?
    return true if can? :read, Stock
    return true if can? :read, StockMovement
    return true if can? :read, ListingStock
  end
  
  def setting_menu_active?
    return true if can? :read, Email
    return true if can? :read, User
    return true if can? :manage, AvailableMenu
    return true if can? :read, FiscalYear
    return true if can? :read, Event
    return true if can? :read, Member
  end

  def cashier_menu_active?
    return true if can? :read, CashierOpening
    return true if can? :manage, CashierOpening
    return true if can? :read, CashDisbursement
  end

  def goods_in_transit_active?
    return true if can? :read_shipment_goods, Shipment
    return true if can? :read_mutation_goods, StockMutation
  end
end
