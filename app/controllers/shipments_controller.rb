include SmartListing::Helper::ControllerExtensions
class ShipmentsController < ApplicationController
  helper SmartListing::Helper
  authorize_resource except: :create
  before_action :set_shipment, only: [:show, :edit, :update, :destroy, :change_receive_date]

  # GET /shipments
  # GET /shipments.json
  def index
    like_command = "ILIKE"
    if params[:filter_delivery_date].present?
      splitted_delivery_date_range = params[:filter_delivery_date].split("-")
      start_delivery_date = splitted_delivery_date_range[0].strip.to_date
      end_delivery_date = splitted_delivery_date_range[1].strip.to_date
    end
    if params[:filter_received_date].present?
      splitted_received_date_range = params[:filter_received_date].split("-")
      start_received_date = splitted_received_date_range[0].strip.to_date
      end_received_date = splitted_received_date_range[1].strip.to_date
    end
    shipments_scope = if current_user.has_non_spg_role?
      Shipment.
        select(:id, :delivery_order_number, :delivery_date, :received_date, :quantity, :is_document_printed, "users.name AS user_name").
        joins(:order_booking).
        joins(:audits).
        joins("INNER JOIN users ON users.id = audits.user_id AND audits.user_type = 'User' AND audits.action = 'create'")
    else
      Shipment.
        select(:id, :delivery_order_number, :delivery_date, :received_date, :quantity, :is_document_printed, "users.name AS user_name").
        joins(:order_booking).
        joins(:audits).
        joins("INNER JOIN users ON users.id = audits.user_id AND audits.user_type = 'User' AND audits.action = 'create'").
        where("order_bookings.destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}")
    end
    shipments_scope = shipments_scope.where(["delivery_order_number #{like_command} ? OR users.name #{like_command} ?", "%"+params[:filter_string]+"%", "%"+params[:filter_string]+"%"]) if params[:filter_string].present?
    shipments_scope = shipments_scope.where(["DATE(delivery_date) BETWEEN ? AND ?", start_delivery_date, end_delivery_date]) if params[:filter_delivery_date].present?
    shipments_scope = shipments_scope.where(["DATE(received_date) BETWEEN ? AND ?", start_received_date, end_received_date]) if params[:filter_received_date].present?
    shipments_scope = shipments_scope.where(["destination_warehouse_id = ?", params[:filter_destination_warehouse]]) if params[:filter_destination_warehouse].present?
    @shipments = smart_listing_create(:shipments, shipments_scope, partial: 'shipments/listing', default_sort: {delivery_order_number: "asc"})
  end

  # GET /shipments
  # GET /shipments.json
  def inventory_receipts
    like_command = "ILIKE"
    if params[:filter_delivery_date].present?
      splitted_delivery_date_range = params[:filter_delivery_date].split("-")
      start_delivery_date = splitted_delivery_date_range[0].strip.to_date
      end_delivery_date = splitted_delivery_date_range[1].strip.to_date
    end
    if params[:filter_received_date].present?
      splitted_received_date_range = params[:filter_received_date].split("-")
      start_received_date = splitted_received_date_range[0].strip.to_date
      end_received_date = splitted_received_date_range[1].strip.to_date
    end
    shipments_scope = if current_user.has_non_spg_role?
      Shipment.
        select(:id, :delivery_order_number, :delivery_date, :received_date, :quantity, :is_receive_date_changed, "users.name AS user_name").
        joins(:order_booking).
        joins(:audits).
        joins("INNER JOIN users ON users.id = audits.user_id AND audits.user_type = 'User' AND audits.action = 'create'").
        where(is_document_printed: true)
    else
      Shipment.
        select(:id, :delivery_order_number, :delivery_date, :received_date, :quantity, :is_receive_date_changed, "users.name AS user_name").
        joins(:order_booking).
        joins(:audits).
        joins("INNER JOIN users ON users.id = audits.user_id AND audits.user_type = 'User' AND audits.action = 'create'").
        where(is_document_printed: true).
        where("order_bookings.destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}")
    end
    shipments_scope = shipments_scope.where(["delivery_order_number #{like_command} ? OR users.name #{like_command} ?", "%"+params[:filter_string]+"%", "%"+params[:filter_string]+"%"]) if params[:filter_string].present?
    shipments_scope = shipments_scope.where(["DATE(delivery_date) BETWEEN ? AND ?", start_delivery_date, end_delivery_date]) if params[:filter_delivery_date].present?
    shipments_scope = shipments_scope.where(["DATE(received_date) BETWEEN ? AND ?", start_received_date, end_received_date]) if params[:filter_received_date].present?
    shipments_scope = shipments_scope.where(["destination_warehouse_id = ?", params[:filter_destination_warehouse]]) if params[:filter_destination_warehouse].present?
    @shipments = smart_listing_create(:shipments, shipments_scope, partial: 'shipments/listing_inventory_receipt', default_sort: {delivery_order_number: "asc"})
  end

  # GET /shipments/1
  # GET /shipments/1.json
  def show
  end

  def print
    @company = Company.select(:id, :name, :address, :phone, :fax).first
    @shipment = Shipment.
      select("shipments.*", "order_bookings.note AS ob_note", "accounts_receivable_invoices.id AS ari_id", "accounts_receivable_invoices.number AS ari_number", "accounts_receivable_invoices.due_date AS ari_due_date", "accounts_receivable_invoices.note AS ari_note", "customers.name AS customer_name", "customers.phone AS customer_phone", "customers.facsimile AS customer_facsimile", "customers.is_taxable_entrepreneur AS customer_is_taxable_entrepreneur", "customers.value_added_tax AS customer_vat_type").
      includes(shipment_product_items: [:price_list, order_booking_product_item: [:color, :size, order_booking_product: [product: :brand]]]).
      joins(order_booking: :customer).
      joins("LEFT JOIN accounts_receivable_invoices ON shipments.id = accounts_receivable_invoices.shipment_id").
      find(params[:id])
    @shipment.update(is_document_printed: true)
  end

  def multiprint
    @company = Company.select(:id, :name, :address, :phone, :fax).first
    @shipments = Shipment.
      select("shipments.*", "order_bookings.note AS ob_note", "accounts_receivable_invoices.id AS ari_id", "accounts_receivable_invoices.number AS ari_number", "accounts_receivable_invoices.due_date AS ari_due_date", "accounts_receivable_invoices.note AS ari_note", "customers.name AS customer_name", "customers.phone AS customer_phone", "customers.facsimile AS customer_facsimile", "customers.is_taxable_entrepreneur AS customer_is_taxable_entrepreneur", "customers.value_added_tax AS customer_vat_type").
      includes(shipment_product_items: [:price_list, order_booking_product_item: [:color, :size, order_booking_product: [product: :brand]]]).
      joins(order_booking: :customer).
      joins("LEFT JOIN accounts_receivable_invoices ON shipments.id = accounts_receivable_invoices.shipment_id").
      where(id: params[:check]).
      order(:id)
    @shipments.update_all(is_document_printed: true)
    respond_to do |format|
      format.js
    end
  end

  # GET /shipments/new
  def new
    @shipment = Shipment.new
  end

  # POST /shipments
  # POST /shipments.json
  def create
    add_additional_params
    @invalid = false
    ActiveRecord::Base.transaction do
      @shipments = []
      params[:shipments].each do |shipment_index|
        begin
          shipment = Shipment.new(shipment_params(params[:shipments][shipment_index]))
          authorize! :undelete_action, shipment
          unless shipment.save
            if shipment.errors[:base].present?
              render js: "bootbox.alert({message: \"#{shipment.errors[:base].join("<br/>")}\",size: 'small'});"
              raise ActiveRecord::Rollback
            elsif shipment.errors[:"shipment_products.base"].present?
              render js: "bootbox.alert({message: \"#{shipment.errors[:"shipment_products.base"].join("<br/>")}\",size: 'small'});"
              raise ActiveRecord::Rollback
            elsif shipment.errors[:"shipment_products.shipment_product_items.base"].present?
              render js: "bootbox.alert({message: \"#{shipment.errors[:"shipment_products.shipment_product_items.base"].join("<br/>")}\",size: 'small'});"
              raise ActiveRecord::Rollback
            else
              if params[:shipments][shipment_index][:order_booking_id].present?
                order_booking = OrderBooking.printed.where(id: params[:shipments][shipment_index][:order_booking_id]).select(:id).first
                order_booking.order_booking_products.select(:id).each do |order_booking_product|
                  shipment_product = shipment.shipment_products.select{|sp| sp.order_booking_product_id == order_booking_product.id}.first
                  shipment_product = shipment.shipment_products.build order_booking_product_id: order_booking_product.id if shipment_product.blank?
                  order_booking_product.order_booking_product_items.select(:id).each do |order_booking_product_item|
                    shipment_product.shipment_product_items.build order_booking_product_item_id: order_booking_product_item.id if shipment_product.shipment_product_items.select{|spi| spi.order_booking_product_item_id == order_booking_product_item.id}.blank?
                  end
                end if order_booking.present?
              end
              @invalid = true
            end
          else
            shipment.delivery_date = shipment.delivery_date.strftime("%d/%m/%Y")
          end
          @shipments << shipment
        rescue ActiveRecord::RecordNotUnique => e
          render js: "bootbox.alert({message: \"Something went wrong. Please try again\",size: 'small'});"
          raise ActiveRecord::Rollback
        end
      end
      raise ActiveRecord::Rollback if @invalid
    end
  end

  #  def edit
  #    @shipment.delivery_date = @shipment.delivery_date.strftime("%d/%m/%Y")
  #  end
  #
  #  def update
  #    add_additional_params_for_edit
  #    @valid = @shipment.update(edit_shipment_params)
  #    if @shipment.errors[:base].present?
  #      render js: "bootbox.alert({message: \"#{@shipment.errors[:base].join("<br/>")}\",size: 'small'});"
  #    elsif @shipment.errors[:"shipment_products.base"].present?
  #      render js: "bootbox.alert({message: \"#{@shipment.errors[:"shipment_products.base"].join("<br/>")}\",size: 'small'});"
  #    elsif @shipment.errors[:"shipment_products.shipment_product_items.base"].present?
  #      render js: "bootbox.alert({message: \"#{@shipment.errors[:"shipment_products.shipment_product_items.base"].join("<br/>")}\",size: 'small'});"
  #    end
  #  end

  # DELETE /shipments/1
  # DELETE /shipments/1.json
  def destroy
    @shipment.attr_user_id = current_user.id
    unless @shipment.destroy
      @deleted = false
    else
      @deleted = true
    end
  end

  def generate_ob_detail
    order_booking_ids = params[:order_booking_ids].split(",")
    order_booking_numbers = params[:order_booking_numbers].split(",")
    order_bookings = OrderBooking.printed.where(id: order_booking_ids).select(:id, :number).order(:number)
    unavailable_obs = []
    order_booking_ids.each_with_index do |order_booking_id, index|
      if order_bookings.select{|order_booking| order_booking.id == order_booking_id.to_i}.blank?
        unavailable_obs << order_booking_numbers[index]
      end
    end
    if unavailable_obs.length == 1
      render js: "bootbox.alert({message: \"Order booking #{unavailable_obs.to_sentence} is not available\",size: 'small'});"
    elsif unavailable_obs.length > 1
      render js: "bootbox.alert({message: \"Order booking #{unavailable_obs.to_sentence} are not available\"});"
    else      
      @shipments = []
      order_bookings.each do |order_booking|
        shipment = Shipment.new order_booking_id: order_booking.id, order_booking_number: order_booking.number, delivery_date: params[:delivery_date], courier_id: params[:courier_id]
        order_booking.order_booking_products.select(:id).each do |order_booking_product|
          shipment_product = shipment.shipment_products.build order_booking_product_id: order_booking_product.id
          order_booking_product.order_booking_product_items.select(:id).each do |order_booking_product_item|
            shipment_product.shipment_product_items.build order_booking_product_item_id: order_booking_product_item.id
          end
        end
        @shipments << shipment
      end
    end
  end

  def receive
    @shipment = if current_user.has_non_spg_role?
      Shipment.where(id: params[:id], is_document_printed: true).first
    else
      Shipment.joins(:order_booking).where(id: params[:id], is_document_printed: true).where("order_bookings.destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").first
    end
    if @shipment.present?
      @shipment.with_lock do
        @shipment.update(received_date: params[:receive_date], receiving_inventory: true)
      end
      if @shipment.errors[:base].present?
        render js: "bootbox.alert({message: \"#{@shipment.errors[:base].join("<br/>")}\",size: 'small'});"
      elsif @shipment.errors[:received_date].present?
        render js: "bootbox.alert({message: \"Receive date #{@shipment.errors[:received_date].join("<br/>")}\",size: 'small'});"
      end
    else
      render js: "bootbox.alert({message: \"No records found\",size: 'small'});"
    end
  end

  def search_do
    @shipments = if current_user.has_non_spg_role?
      Shipment.select(:id, :delivery_order_number).joins(:order_booking).where(["(shipments.delivery_order_number = ? OR order_bookings.number = ?) AND received_date IS NULL", params[:do_ob_number], params[:do_ob_number]]).where(is_document_printed: true)
    else
      Shipment.select(:id, :delivery_order_number).joins(:order_booking).where("order_bookings.destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").where(["(shipments.delivery_order_number = ? OR order_bookings.number = ?) AND received_date IS NULL", params[:do_ob_number], params[:do_ob_number]]).where(is_document_printed: true)
    end

    # apabila jumlahnya lebih dari satu maka artinya satu DO bisa banyak OB, jadi tidak bisa search by OB number (tapi sekarang 1 DO = 1 OB)
    if @shipments.length == 0 || @shipments.length > 1
      render js: "var box = bootbox.alert({message: \"No records found\",size: 'small'});box.on(\"hidden.bs.modal\", function () {$(\"#do_ob_number\").focus();});"
    end
  end

  def change_receive_date
    @updated = false
    @shipment.with_lock do
      @updated = @shipment.update(received_date: params[:receive_date], attr_change_receive_date: true)
    end
    if !@updated
      if @shipment.errors[:base].present?
        render js: "bootbox.alert({message: \"#{@shipment.errors[:base].join("<br/>")}\",size: 'small'});"
      elsif @shipment.errors[:received_date].present?
        render js: "bootbox.alert({message: \"Receive date #{@shipment.errors[:received_date].join("<br/>")}\",size: 'small'});"
      end
    end
  end  
  
  def direct_sales
    if params[:filter_date_direct_sales].present?
      splitted_date_range = params[:filter_date_direct_sales].split("-")
      start_delivery_date = splitted_date_range[0].strip.to_date
      end_delivery_date = splitted_date_range[1].strip.to_date
    end

    shipments_scope = Shipment.
      select(:id, :delivery_order_number, :delivery_date, :quantity, "customers.code AS customer_code", "customers.name AS customer_name", "accounts_receivable_invoices.total AS net_total").
      joins(:accounts_receivable_invoice, order_booking: :customer)
    
    shipments_scope = shipments_scope.where(["shipments.delivery_order_number ILIKE ?", "%"+params[:filter_string_direct_sales]+"%"]) if params[:filter_string_direct_sales].present?
    shipments_scope = shipments_scope.where(["shipments.delivery_date BETWEEN ? AND ?", start_delivery_date, end_delivery_date]) if params[:filter_date_direct_sales].present?
    shipments_scope = shipments_scope.where(["order_bookings.customer_id = ?", params[:filter_customer_direct_sales]]) if params[:filter_customer_direct_sales].present?
    smart_listing_create(:shipments, shipments_scope, partial: 'shipments/listing_direct_sales', default_sort: {delivery_order_number: "asc"})
  end
  
  def show_direct_sale
    @shipment = Shipment.
      select(:id, :delivery_order_number, :delivery_date, :quantity, "customers.code AS customer_code", "customers.name AS customer_name", "customers.is_taxable_entrepreneur AS customer_is_taxable_entrepreneur", "customers.value_added_tax AS customer_vat_type", "accounts_receivable_invoices.discount AS customer_discount", "accounts_receivable_invoices.total AS net_total").
      joins(:accounts_receivable_invoice, order_booking: :customer).
      find(params[:id])
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_shipment
    @shipment = if current_user.has_non_spg_role?
      Shipment.select("shipments.*", "order_bookings.note AS ob_note").joins(:order_booking).find(params[:id])
    else
      Shipment.joins(:order_booking).where(id: params[:id]).
        where("order_bookings.destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").
        select("shipments.*", "order_bookings.note AS ob_note").first
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def shipment_params(params)
    params.permit(:order_booking_number, :quantity, :delivery_date, :order_booking_id, :courier_id,
      shipment_products_attributes: [:order_booking_product_id, :order_booking_id, :quantity,
        shipment_product_items_attributes: [:order_booking_product_item_id, :quantity,
          :order_booking_product_id, :order_booking_id, :attr_delivery_date]])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def edit_shipment_params
    params[:shipment].permit(:order_booking_number, :quantity, :delivery_date, :order_booking_id, :courier_id,
      shipment_products_attributes: [:id, :order_booking_product_id, :order_booking_id, :quantity,
        shipment_product_items_attributes: [:id, :order_booking_product_item_id, :quantity,
          :order_booking_product_id, :order_booking_id]])
  end

  def add_additional_params_for_edit
    total_quantity_shipment = 0
    params[:shipment][:shipment_products_attributes].each do |key, value|
      total_quantity_shipment_product = 0
      params[:shipment][:shipment_products_attributes][key].merge! order_booking_id: params[:shipment][:order_booking_id]
      params[:shipment][:shipment_products_attributes][key][:shipment_product_items_attributes].each do |spi_key, value|
        total_quantity_shipment += params[:shipment][:shipment_products_attributes][key][:shipment_product_items_attributes][spi_key][:quantity].to_i
        total_quantity_shipment_product += params[:shipment][:shipment_products_attributes][key][:shipment_product_items_attributes][spi_key][:quantity].to_i
        params[:shipment][:shipment_products_attributes][key][:shipment_product_items_attributes][spi_key].merge! order_booking_product_id: params[:shipment][:shipment_products_attributes][key][:order_booking_product_id], order_booking_id: params[:shipment][:order_booking_id]
      end if params[:shipment][:shipment_products_attributes][key][:shipment_product_items_attributes].present?
      params[:shipment][:shipment_products_attributes][key].merge! quantity: total_quantity_shipment_product
    end if params[:shipment][:shipment_products_attributes].present?
    params[:shipment].merge! quantity: total_quantity_shipment
  end

  def add_additional_params
    params[:shipments].each do |shipments_key, shipments_value|
      total_quantity_shipment = 0
      params[:shipments][shipments_key][:shipment_products_attributes].each do |key, value|
        total_quantity_shipment_product = 0
        params[:shipments][shipments_key][:shipment_products_attributes][key].merge! order_booking_id: params[:shipments][shipments_key][:order_booking_id]
        params[:shipments][shipments_key][:shipment_products_attributes][key][:shipment_product_items_attributes].each do |spi_key, value|
          total_quantity_shipment += params[:shipments][shipments_key][:shipment_products_attributes][key][:shipment_product_items_attributes][spi_key][:quantity].to_i
          total_quantity_shipment_product += params[:shipments][shipments_key][:shipment_products_attributes][key][:shipment_product_items_attributes][spi_key][:quantity].to_i
          params[:shipments][shipments_key][:shipment_products_attributes][key][:shipment_product_items_attributes][spi_key].merge! order_booking_product_id: params[:shipments][shipments_key][:shipment_products_attributes][key][:order_booking_product_id], order_booking_id: params[:shipments][shipments_key][:order_booking_id], attr_delivery_date: params[:shipments][shipments_key][:delivery_date]
        end if params[:shipments][shipments_key][:shipment_products_attributes][key][:shipment_product_items_attributes].present?
        params[:shipments][shipments_key][:shipment_products_attributes][key].merge! quantity: total_quantity_shipment_product
      end if params[:shipments][shipments_key][:shipment_products_attributes].present?
      params[:shipments][shipments_key].merge! quantity: total_quantity_shipment
    end
  end
end
