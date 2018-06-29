class Api::ConsignmentSalesController < Api::ApplicationController
  before_action :authenticate_user!
  authorize_resource
  #  before_action :set_consignment_sale, only: [:edit, :update, :destroy, :approve, :unapprove]

  # GET /consignment_sales/new
  def new
    @counters = if current_user.has_role?(:area_manager)
      current_user.supervisor.warehouses.counter.select(:id, :code, :name)
    elsif current_user.has_non_spg_role?
      Warehouse.select(:id, :code, :name).counter
    end
  end
  
  def get_events
    @events = if current_user.has_non_spg_role?
      CounterEvent.select(:id, :code, :name).joins(:counter_event_warehouses).where(["DATE(counter_events.start_time) <= ? AND DATE(counter_events.end_time) >= ? AND counter_event_warehouses.warehouse_id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date, params[:transaction_date].to_date, params[:warehouse_id], true, true])
    else
      CounterEvent.select(:id, :code, :name).joins(:counter_event_warehouses).where(["DATE(counter_events.start_time) <= ? AND DATE(counter_events.end_time) >= ? AND counter_event_warehouses.warehouse_id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date, params[:transaction_date].to_date, current_user.sales_promotion_girl.warehouse_id, true, true])
    end      
  end

end
