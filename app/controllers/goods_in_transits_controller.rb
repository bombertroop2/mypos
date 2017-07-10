include SmartListing::Helper::ControllerExtensions
class GoodsInTransitsController < ApplicationController
  helper SmartListing::Helper

  def shipment_goods
    authorize! :read_shipment_goods, Shipment
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    if params[:filter_delivery_date].present?
      splitted_delivery_date_range = params[:filter_delivery_date].split("-")
      start_delivery_date = splitted_delivery_date_range[0].strip.to_date
      end_delivery_date = splitted_delivery_date_range[1].strip.to_date
    end
    shipments_scope = if current_user.has_non_spg_role?
      Shipment.select(:id, :delivery_order_number, :delivery_date, :quantity).
        joins(:order_booking).where("received_date IS NULL")
    else
      Shipment.select(:id, :delivery_order_number, :delivery_date, :quantity).
        joins(:order_booking).
        where("order_bookings.destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").
        where("received_date IS NULL")
    end
    shipments_scope = shipments_scope.where(["delivery_order_number #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(shipments_scope.where(["shipments.quantity #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string].present?
    shipments_scope = shipments_scope.where(["DATE(delivery_date) BETWEEN ? AND ?", start_delivery_date, end_delivery_date]) if params[:filter_delivery_date].present?
    shipments_scope = shipments_scope.where(["destination_warehouse_id = ?", params[:filter_destination_warehouse]]) if params[:filter_destination_warehouse].present?
    @shipments = smart_listing_create(:shipments, shipments_scope, partial: 'goods_in_transits/listing_shipment_goods', default_sort: {delivery_order_number: "asc"})
  end
  
  def show_shipment_goods
    @shipment = if current_user.has_non_spg_role?
      Shipment.where(id: params[:id]).where("received_date IS NULL").first
    else
      Shipment.joins(:order_booking).where(id: params[:id]).
        where("order_bookings.destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id} AND received_date IS NULL").
        select("shipments.*").first
    end
    authorize! :read_shipment_goods, @shipment
  end

  def mutation_goods
    authorize! :read_mutation_goods, StockMutation
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    if params[:filter_delivery_date].present?
      splitted_delivery_date_range = params[:filter_delivery_date].split("-")
      start_delivery_date = splitted_delivery_date_range[0].strip.to_date
      end_delivery_date = splitted_delivery_date_range[1].strip.to_date
    end
    stock_mutations_scope = if current_user.has_non_spg_role?
      StockMutation.joins(:destination_warehouse).
        select(:id, :number, :delivery_date, :quantity,
        :destination_warehouse_id).
        where("warehouse_type <> 'central' AND approved_date IS NOT NULL AND received_date IS NULL")
    else
      StockMutation.joins(:destination_warehouse).
        select(:id, :number, :delivery_date, :quantity).
        where("warehouse_type <> 'central' AND origin_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id} AND approved_date IS NOT NULL AND received_date IS NULL")
    end
    stock_mutations_scope = stock_mutations_scope.where(["number #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(stock_mutations_scope.where(["quantity #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string].present?
    stock_mutations_scope = stock_mutations_scope.where(["DATE(delivery_date) BETWEEN ? AND ?", start_delivery_date, end_delivery_date]) if params[:filter_delivery_date].present?
    #    shipments_scope = shipments_scope.where(["destination_warehouse_id = ?", params[:filter_destination_warehouse]]) if params[:filter_destination_warehouse].present?
    @stock_mutations = smart_listing_create(:stock_mutations, stock_mutations_scope, partial: 'goods_in_transits/listing_mutation_goods', default_sort: {number: "asc"})
  end

  def show_mutation_goods
    @stock_mutation = if current_user.has_non_spg_role?
      StockMutation.joins(:destination_warehouse).where(id: params[:id]).
        where("warehouse_type <> 'central' AND approved_date IS NOT NULL AND received_date IS NULL").first
    else
      StockMutation.joins(:destination_warehouse).where(id: params[:id]).
        where("warehouse_type <> 'central' AND approved_date IS NOT NULL AND received_date IS NULL AND origin_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").first
    end
    authorize! :read_mutation_goods, @stock_mutation
  end
  
  def returned_goods
  end
end
