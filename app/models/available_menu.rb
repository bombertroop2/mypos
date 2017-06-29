class AvailableMenu < ApplicationRecord
  MENUS = ["Brand", "Color", "Model", "Goods Type", "Region", "Vendor", "Product",
    "Size Group", "Sales Promotion Girl", "Area Manager", "Warehouse", "Purchase Order",
    "Receiving", "Stock Balance", "Purchase Return", "Cost & Price", "Email", "Account Payable",
    "Order Booking", "Courier", "Shipment", "Shipment Receipt"]

  validates :name, presence: true
  
end
