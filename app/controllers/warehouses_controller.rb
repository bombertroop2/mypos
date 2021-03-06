include SmartListing::Helper::ControllerExtensions
class WarehousesController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_warehouse, only: [:show, :edit, :update, :destroy]

  # GET /warehouses
  # GET /warehouses.json
  def index
    like_command = "ILIKE"
    warehouses_scope = Warehouse.
      joins("LEFT JOIN supervisors ON supervisors.id = warehouses.supervisor_id").
      joins("LEFT JOIN common_fields ON common_fields.id = warehouses.region_id AND common_fields.type IN ('Region')").
      select("warehouses.id, warehouses.code, warehouses.name, supervisors.name AS supervisor_name, common_fields.code AS region_code, warehouse_type")
    warehouses_scope = warehouses_scope.where(["warehouses.code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(warehouses_scope.where(["warehouses.name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(warehouses_scope.where(["supervisors.name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(warehouses_scope.where(["common_fields.code #{like_command} ?", "%"+params[:filter]+"%"])).
      or(warehouses_scope.where(["warehouse_type #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @warehouses = smart_listing_create(:warehouses, warehouses_scope, partial: 'warehouses/listing', default_sort: {:"warehouses.code" => "asc"})
  end

  # GET /warehouses/1
  # GET /warehouses/1.json
  def show
  end

  # GET /warehouses/new
  def new
    @warehouse = Warehouse.new
  end

  # GET /warehouses/1/edit
  def edit
    splitted_code = @warehouse.code.split("-")
    first_code = splitted_code[0].gsub(" ", "_").rjust(4, "_") rescue "____"
    second_code = splitted_code[1].gsub(" ", "_").ljust(4, "_") rescue "____"
    @warehouse.code = "#{first_code}-#{second_code}"
  end

  # POST /warehouses
  # POST /warehouses.json
  def create
    @warehouse = Warehouse.new(warehouse_params)
    
    begin
      if @created = @warehouse.save
        unless @warehouse.warehouse_type.eql?("in_transit")
          @new_supervisor_name = Supervisor.select(:name).where(id: params[:warehouse][:supervisor_id]).first.name
          @new_region_code = Region.select(:code).where(id: params[:warehouse][:region_id]).first.code
        else
          @new_supervisor_name = nil
          @new_region_code = nil
        end
      else
        splitted_code = @warehouse.code.split("-")
        first_code = splitted_code[0].gsub(" ", "_").rjust(4, "_") rescue "____"
        second_code = splitted_code[1].gsub(" ", "_").ljust(4, "_") rescue "____"
        @warehouse.code = "#{first_code}-#{second_code}"
      end
    rescue ActiveRecord::RecordNotUnique => e
      splitted_code = @warehouse.code.split("-")
      first_code = splitted_code[0].gsub(" ", "_").rjust(4, "_") rescue "____"
      second_code = splitted_code[1].gsub(" ", "_").ljust(4, "_") rescue "____"
      @warehouse.code = "#{first_code}-#{second_code}"
      if e.cause.to_s.include?("code")      
        @warehouse.errors.messages[:code] = ["has already been taken"]
      end
    end
  end

  # PATCH/PUT /warehouses/1
  # PATCH/PUT /warehouses/1.json
  def update    
    begin
      supervisor_id_was = @warehouse.supervisor_id_was
      region_id_was = @warehouse.region_id_was
      if @updated = @warehouse.update(warehouse_params)
        unless @warehouse.warehouse_type.eql?("in_transit")
          #cek apakah supervisor diganti
          unless supervisor_id_was.to_s.eql?(params[:warehouse][:supervisor_id])
            @new_supervisor_name = Supervisor.select(:name).where(id: params[:warehouse][:supervisor_id]).first.name
          end
        
          #cek apakah region diganti
          unless region_id_was.to_s.eql?(params[:warehouse][:region_id])
            @new_region_code = Region.select(:code).where(id: params[:warehouse][:region_id]).first.code
          end
        else
          @new_supervisor_name = nil
          @new_region_code = nil
        end
      else
        splitted_code = @warehouse.code.split("-")
        first_code = splitted_code[0].gsub(" ", "_").rjust(4, "_") rescue "____"
        second_code = splitted_code[1].gsub(" ", "_").ljust(4, "_") rescue "____"
        @warehouse_code = "#{first_code}-#{second_code}"
      end
    rescue ActiveRecord::RecordNotUnique => e
      splitted_code = @warehouse.code.split("-")
      first_code = splitted_code[0].gsub(" ", "_").rjust(4, "_") rescue "____"
      second_code = splitted_code[1].gsub(" ", "_").ljust(4, "_") rescue "____"
      @warehouse_code = "#{first_code}-#{second_code}"
      if e.cause.to_s.include?("code")      
        @warehouse.errors.messages[:code] = ["has already been taken"]
      end
    end
  end

  # DELETE /warehouses/1
  # DELETE /warehouses/1.json
  def destroy
    @warehouse.destroy
    if @warehouse.errors.present? and @warehouse.errors.messages[:base].present?
      flash[:alert] = @warehouse.errors.messages[:base].to_sentence
      render js: "window.location = '#{warehouses_url}'"
    end
  end
  
  def get_cities
    @cities = City.select(:id, :name).where(province_id: params[:province_id]).order(:name)
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_warehouse
    @warehouse = Warehouse.
      joins("LEFT JOIN supervisors ON supervisors.id = warehouses.supervisor_id").
      joins("LEFT JOIN common_fields ON common_fields.id = warehouses.region_id AND common_fields.type IN ('Region')").
      joins("LEFT JOIN common_fields price_codes_warehouses ON price_codes_warehouses.id = warehouses.price_code_id AND price_codes_warehouses.type IN ('PriceCode')").
      where(id: params[:id]).
      select("warehouses.id, warehouses.code, warehouses.name, warehouses.address, is_active, supervisors.name AS supervisor_name, common_fields.code AS region_code, price_codes_warehouses.code AS price_code_code, warehouse_type, supervisor_id, region_id, price_code_id").
      select(:province_id, :city_id, :first_message, :second_message, :third_message, :fourth_message, :fifth_message, :sku, :counter_type, :estimated_delivery_time).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def warehouse_params
    params.require(:warehouse).permit(:code, :name, :address, :supervisor_id, :region_id, :warehouse_type, :price_code_id, :first_message, :second_message, :third_message, :fourth_message, :fifth_message, :sku, :counter_type, :province_id, :city_id, :estimated_delivery_time)
  end
end
