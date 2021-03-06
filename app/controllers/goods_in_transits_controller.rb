include SmartListing::Helper::ControllerExtensions
class GoodsInTransitsController < ApplicationController
  helper SmartListing::Helper

  def shipment_goods
    authorize! :read_shipment_goods, Shipment
    like_command = "ILIKE"
    if params[:filter_delivery_date].present?
      splitted_delivery_date_range = params[:filter_delivery_date].split("-")
      start_delivery_date = splitted_delivery_date_range[0].strip.to_date
      end_delivery_date = splitted_delivery_date_range[1].strip.to_date
    end
    @user_roles = current_user.roles.pluck :name
    shipments_scope = if @user_roles.include?("area_manager")
      unless request.xhr?
        @warehouses = current_user.supervisor.warehouses.actived.select(:id, :code, :name)
        warehouse_ids = @warehouses.pluck(:id)
        Shipment.select(:id, :delivery_order_number, :delivery_date, :quantity).
          joins(order_booking: [:origin_warehouse, :destination_warehouse]).
          where(:"order_bookings.destination_warehouse_id" => warehouse_ids).
          where(["received_date IS NULL AND warehouses.is_active = ? AND destination_warehouses_order_bookings.is_active = ?", true, true])
      else
        Shipment.select(:id, :delivery_order_number, :delivery_date, :quantity).
          joins(order_booking: [:origin_warehouse, :destination_warehouse]).
          where(["received_date IS NULL AND warehouses.is_active = ? AND destination_warehouses_order_bookings.is_active = ?", true, true])
      end
    elsif @user_roles.include?("staff") || @user_roles.include?("manager") || @user_roles.include?("administrator") || @user_roles.include?("superadmin") || @user_roles.include?("accountant")
      unless request.xhr?
        @warehouses = Warehouse.not_central.actived.select(:id, :code, :name)
      end
      Shipment.select(:id, :delivery_order_number, :delivery_date, :quantity).
        joins(order_booking: [:origin_warehouse, :destination_warehouse]).where(["received_date IS NULL AND warehouses.is_active = ? AND destination_warehouses_order_bookings.is_active = ?", true, true])
    else
      Shipment.select(:id, :delivery_order_number, :delivery_date, :quantity).
        joins(order_booking: [:origin_warehouse, :destination_warehouse]).
        where("order_bookings.destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").
        where(["received_date IS NULL AND warehouses.is_active = ? AND destination_warehouses_order_bookings.is_active = ?", true, true])
    end
    shipments_scope = shipments_scope.where(["delivery_order_number #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(shipments_scope.where(["shipments.quantity #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string].present?
    shipments_scope = shipments_scope.where(["DATE(delivery_date) BETWEEN ? AND ?", start_delivery_date, end_delivery_date]) if params[:filter_delivery_date].present?
    shipments_scope = shipments_scope.where(["destination_warehouse_id = ?", params[:filter_destination_warehouse]]) if params[:filter_destination_warehouse].present?
    @shipments = smart_listing_create(:shipments, shipments_scope, partial: 'goods_in_transits/listing_shipment_goods', default_sort: {delivery_order_number: "asc"})
  end
  
  def show_shipment_goods
    @shipment = if current_user.has_non_spg_role?
      Shipment.select("shipments.*", "order_bookings.note AS ob_note").joins(order_booking: [:origin_warehouse, :destination_warehouse]).where(id: params[:id]).where(["received_date IS NULL AND warehouses.is_active = ? AND destination_warehouses_order_bookings.is_active = ?", true, true]).first
    else
      Shipment.joins(order_booking: [:origin_warehouse, :destination_warehouse]).where(id: params[:id]).
        where("order_bookings.destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id} AND received_date IS NULL").
        where(["warehouses.is_active = ? AND destination_warehouses_order_bookings.is_active = ?", true, true]).
        select("shipments.*", "order_bookings.note AS ob_note").first
    end
    authorize! :read_shipment_goods, @shipment
  end

  def mutation_goods
    authorize! :read_mutation_goods, StockMutation
    like_command = "ILIKE"
    if params[:filter_delivery_date].present?
      splitted_delivery_date_range = params[:filter_delivery_date].split("-")
      start_delivery_date = splitted_delivery_date_range[0].strip.to_date
      end_delivery_date = splitted_delivery_date_range[1].strip.to_date
    end
    user_roles = current_user.roles.pluck :name
    stock_mutations_scope = if user_roles.include?("area_manager")
      warehouse_ids = current_user.supervisor.warehouses.pluck(:id)
      StockMutation.joins(:destination_warehouse).
        select(:id, :number, :delivery_date, :quantity,
        :destination_warehouse_id).
        where(origin_warehouse_id: warehouse_ids).
        where("warehouse_type <> 'central' AND approved_date IS NOT NULL AND received_date IS NULL").
        where(["warehouses.is_active = ?", true])
    elsif user_roles.include?("staff") || user_roles.include?("manager") || user_roles.include?("administrator") || user_roles.include?("superadmin") || user_roles.include?("accountant")
      StockMutation.joins(:destination_warehouse).
        select(:id, :number, :delivery_date, :quantity,
        :destination_warehouse_id).
        where("warehouse_type <> 'central' AND approved_date IS NOT NULL AND received_date IS NULL").
        where(["warehouses.is_active = ?", true])
    else
      StockMutation.joins(:destination_warehouse).
        select(:id, :number, :delivery_date, :quantity).
        where("warehouse_type <> 'central' AND origin_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id} AND approved_date IS NOT NULL AND received_date IS NULL").
        where(["warehouses.is_active = ?", true])
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
        where("warehouse_type <> 'central' AND approved_date IS NOT NULL AND received_date IS NULL").
        where(["warehouses.is_active = ?", true]).first
    else
      StockMutation.joins(:destination_warehouse).where(id: params[:id]).
        where("warehouse_type <> 'central' AND approved_date IS NOT NULL AND received_date IS NULL AND origin_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").
        where(["warehouses.is_active = ?", true]).first
    end
    authorize! :read_mutation_goods, @stock_mutation
  end
  
  def returned_goods
    authorize! :read_mutation_goods, StockMutation
    like_command = "ILIKE"
    if params[:filter_delivery_date].present?
      splitted_delivery_date_range = params[:filter_delivery_date].split("-")
      start_delivery_date = splitted_delivery_date_range[0].strip.to_date
      end_delivery_date = splitted_delivery_date_range[1].strip.to_date
    end
    user_roles = current_user.roles.pluck :name
    stock_mutations_scope = if user_roles.include?("area_manager")
      warehouse_ids = current_user.supervisor.warehouses.pluck(:id)
      StockMutation.joins(:destination_warehouse).
        select(:id, :number, :delivery_date, :quantity).
        where(origin_warehouse_id: warehouse_ids).
        where("warehouse_type = 'central' AND received_date IS NULL").
        where(["warehouses.is_active = ?", true])
    elsif user_roles.include?("staff") || user_roles.include?("manager") || user_roles.include?("administrator") || user_roles.include?("superadmin") || user_roles.include?("accountant")
      StockMutation.joins(:destination_warehouse).
        select(:id, :number, :delivery_date, :quantity).
        where("warehouse_type = 'central' AND received_date IS NULL").
        where(["warehouses.is_active = ?", true])
    else
      StockMutation.joins(:destination_warehouse).
        select(:id, :number, :delivery_date, :quantity).
        where("warehouse_type = 'central' AND origin_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id} AND received_date IS NULL").
        where(["warehouses.is_active = ?", true])
    end
    stock_mutations_scope = stock_mutations_scope.where(["number #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(stock_mutations_scope.where(["quantity #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string].present?
    stock_mutations_scope = stock_mutations_scope.where(["DATE(delivery_date) BETWEEN ? AND ?", start_delivery_date, end_delivery_date]) if params[:filter_delivery_date].present?
    #    shipments_scope = shipments_scope.where(["destination_warehouse_id = ?", params[:filter_destination_warehouse]]) if params[:filter_destination_warehouse].present?
    @stock_mutations = smart_listing_create(:stock_mutations, stock_mutations_scope, partial: 'goods_in_transits/listing_returned_goods', default_sort: {number: "asc"})
  end
  
  def show_returned_goods
    @stock_mutation = if current_user.has_non_spg_role?
      StockMutation.joins(:destination_warehouse).where(id: params[:id]).
        where("warehouse_type = 'central' AND received_date IS NULL").
        where(["warehouses.is_active = ?", true]).first
    else
      StockMutation.joins(:destination_warehouse).where(id: params[:id]).
        where("warehouse_type = 'central' AND received_date IS NULL AND origin_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").
        where(["warehouses.is_active = ?", true]).first
    end
    authorize! :read_mutation_goods, @stock_mutation
  end
end
