class Api::StockMutationsController < Api::ApplicationController
  before_action :authenticate_user!
  authorize_resource
  #  before_action :set_stock_mutation, only: [:show, :show_store_to_warehouse_mutation, :edit,
  #    :update, :destroy, :edit_store_to_warehouse, :update_store_to_warehouse,
  #    :delete_store_to_warehouse, :approve, :print_rolling_doc, :print_return_doc]
  
  def store_to_store_inventory_receipts
    #    @stock_mutations = if current_user.has_non_spg_role?
    #      StockMutation.joins(:destination_warehouse).
    #        select(:id, :number, :delivery_date, :received_date, :quantity,
    #        :destination_warehouse_id, :approved_date, :is_receive_date_changed).
    #        where("warehouse_type <> 'central'").where(received_date: nil)
    #    else
    #      StockMutation.joins(:destination_warehouse).
    #        select(:id, :number, :delivery_date, :received_date, :quantity,
    #        :destination_warehouse_id, :approved_date, :is_receive_date_changed).
    #        where("warehouse_type <> 'central' AND destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").
    #        where(received_date: nil)
    #    end
    @stock_mutations = StockMutation.joins(:destination_warehouse).
      select(:id, :number, :delivery_date, :received_date, :quantity,
      :destination_warehouse_id, :approved_date, :is_receive_date_changed).
      where("warehouse_type <> 'central' AND destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").
      where(received_date: nil)
  end
  
  def receive
    #    @stock_mutation = if current_user.has_non_spg_role?
    #      StockMutation.joins(:destination_warehouse).
    #        select("stock_mutations.*").
    #        where("warehouse_type <> 'central'").
    #        where(id: params[:id]).
    #        where(received_date: nil).
    #        first
    #    else
    #      StockMutation.joins(:destination_warehouse).
    #        select("stock_mutations.*").
    #        where("warehouse_type <> 'central' AND destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").
    #        where(id: params[:id]).
    #        where(received_date: nil).
    #        first
    #    end
    @stock_mutation = StockMutation.joins(:destination_warehouse).
      select("stock_mutations.*").
      where("warehouse_type <> 'central' AND destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").
      where(id: params[:id]).
      where(received_date: nil).
      first
    if @stock_mutation.present?
      received = false
      @stock_mutation.with_lock do
        received = @stock_mutation.update(received_date: params[:receive_date], receiving_inventory_to_store: true)
      end
      unless received
        if @stock_mutation.errors[:base].present?
          render json: { status: false, message: @stock_mutation.errors[:base].first }, status: :unprocessable_entity
        elsif @stock_mutation.errors[:received_date].present?
          render json: { status: false, message: "Receive date #{@stock_mutation.errors[:received_date].first}" }, status: :unprocessable_entity
        end
      else
        render json: { status: true, message: "Stock mutation #{@stock_mutation.number} was successfully received" }
      end
    else
      render json: { status: false, message: "No records found" }, status: :unprocessable_entity
    end
  end
  
  def search    
    stock_mutation = StockMutation.joins(:destination_warehouse).
      select(:id, :number).
      where("warehouse_type <> 'central' AND destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").
      where("approved_date IS NOT NULL").
      where(received_date: nil).
      where(number: params[:mutation_number]).
      first
    
    if stock_mutation.blank?
      render json: { status: false, message: "No records found" }, status: :unprocessable_entity
    else
      render json: { status: true, stock_mutation: stock_mutation }
    end
  end

end
