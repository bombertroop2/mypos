module ApplicationHelper
  def remove_empty_space_from_phone_number(number)
    number.gsub("_", "").gsub(" ", "") rescue nil
  end

  def control_group_error(model, field_name)
    " has-error" if model && model.errors[field_name].present?
  end

  def error_help_text(model, field_name, displayed_field_name="")
    "<span class='help-block'>#{displayed_field_name}#{model.errors[field_name].join(", ")}</span>".html_safe if model && model.errors[field_name].present?
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
    return true if can? :read, AccountPayablePayment
  end

  def booking_control_menu_active?
    return true if can? :read, OrderBooking
    return true if can? :read_action_for_staff, Shipment
  end

  def direct_sales_menu_active?
    return true if can? :read_action_for_staff, Shipment
    return true if can? :read, AccountsReceivableInvoice
    return true if can? :read, AccountsReceivablePayment
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
    return true if can? :read, GrowthReport
    return true if can? :read, QuantitySoldChart
    return true if can? :read, SellThru
  end

  def setting_menu_active?
    return true if can? :read, Email
    return true if can? :read, User
    return true if can? :manage, AvailableMenu
    return true if can? :read, FiscalYear
    return true if can? :read, Member
    return true if can? :manage, Company
    return true if can? :manage, BeginningStockProduct
    return true if can? :read, Customer
    return true if can? :manage, Adjustment
    return true if can? :manage, GeneralVariable
    return true if can? :manage, PrintBarcodeTemp
  end

  def event_menu_active?
    return true if can? :read, Event
    return true if can? :read, CounterEvent
  end

  def expedition_menu_active?
    return true if can? :read, Courier
    return true if can? :read, PackingList
    return true if can? :read, AccountPayableCourier
    return true if can? :read, AccountPayableCourierPayment
  end

  def cashier_menu_active?
    return true if can? :read, CashierOpening
    return true if can? :read, CashDisbursement
    return true if can? :read, Sale
    return true if can? :read, SalesReturn
    return true if can? :read, Incentive
  end

  def consignment_menu_active?
    return true if can? :read, ConsignmentSale
    return true if can? :manage, ConsignmentSale
  end

  def goods_in_transit_active?
    return true if can? :read_shipment_goods, Shipment
    return true if can? :read_mutation_goods, StockMutation
  end

  def render_table_with_type(type)
    partial_name = type || "normal"
    render partial: "table_#{partial_name}"
  end

  def is_selected(params_type, type)
    'selected' if params_type.eql?(type)
  end
end
