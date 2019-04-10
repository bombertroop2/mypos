# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class IncentiveJob < ApplicationJob
  queue_as :default

  def perform(cashier_opening_id)
    cashier_opening = CashierOpening.select(:warehouse_id, :closed_at).find(cashier_opening_id)
    if cashier_opening.closed_at.present?
      warehouse = Warehouse.select(:code, :name).find(cashier_opening.warehouse_id)
      sales = Sale.select(:id, :transaction_number).where(cashier_opening_id: cashier_opening_id)
      incentives = []
      sales.each do |sale|
        sale.
          sale_products.
          select(:quantity, :event_id, :total, "sales_promotion_girls.identifier AS product_spg_identifier", "sales_promotion_girls.name AS product_spg_name", "events.event_type AS product_event_type").
          joins("LEFT JOIN events ON sale_products.event_id = events.id").
          joins("LEFT JOIN sales_promotion_girls ON sale_products.product_spg_id = sales_promotion_girls.id").
          each do |sale_product|
          if sale_product.product_spg_identifier.present?        
            incentive = incentives.select {|i| i[:warehouse_code].eql?(warehouse.code) && i[:transaction_date].eql?(cashier_opening.closed_at.to_date) && i[:sales_promotion_girl_identifier].eql?(sale_product.product_spg_identifier) && i[:transaction_number].eql?(sale.transaction_number)}.first
            if incentive.blank?
              incentive = {}
              incentive[:warehouse_code] = warehouse.code
              incentive[:warehouse_name] = warehouse.name
              incentive[:transaction_date] = cashier_opening.closed_at.to_date
              incentive[:sales_promotion_girl_identifier] = sale_product.product_spg_identifier
              incentive[:sales_promotion_girl_name] = sale_product.product_spg_name
              incentive[:transaction_number] = sale.transaction_number
              incentive[:net_sales] = sale_product.total
              incentive[:quantity] = sale_product.quantity
              incentives << incentive
            else
              incentive[:net_sales] += sale_product.total
              incentive[:quantity] += sale_product.quantity
            end
          end
        end
      end
      ActiveRecord::Base.transaction do
        incentives.each do |i|
          incentive = Incentive.new i
          incentive.save
        end
      end
    end
  end
end
