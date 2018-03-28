class AvailableMenu < ApplicationRecord
  MENUS = ["Brand", "Color", "Model", "Goods Type", "Region", "Vendor", "Product",
    "Size Group", "Sales Promotion Girl", "Area Manager", "Warehouse", "Purchase Order",
    "Receiving", "Stock Balance", "Purchase Return", "Cost & Price", "Email", "Account Payable",
    "Order Booking", "Courier", "Shipment", "Stock Mutation", "Goods In Transit",
    "Fiscal Reopening/Closing", "Stock Movement", "Listing Stocks", "Event", "Cashier", "Bank Master",
    "Member", "Sale", "Company"]

  validates :name, presence: true
  
end
