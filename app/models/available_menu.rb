class AvailableMenu < ApplicationRecord
  MENUS = ["Brand", "Color", "Model", "Goods Type", "Region", "Price Code", "Vendor", "Product",
    "Size Group", "Sales Promotion Girl", "Area Manager", "Warehouse", "Purchase Order",
    "Receiving", "Stock Balance", "Purchase Return", "Cost & Price", "Email", "Account Payable",
    "Order Booking", "Courier", "Shipment"]

  validates :name, presence: true
  
end