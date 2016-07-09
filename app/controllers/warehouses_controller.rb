class WarehousesController < ApplicationController
  before_action :set_warehouse, only: [:show, :edit, :update, :destroy]

  # GET /warehouses
  # GET /warehouses.json
  def index
    @warehouses = Warehouse.joins(:supervisor, :region).
      select("warehouses.id, warehouses.code, warehouses.name, supervisors.name AS supervisor_name, common_fields.code AS region_code, warehouse_type")
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
  end

  # POST /warehouses
  # POST /warehouses.json
  def create
    @warehouse = Warehouse.new(warehouse_params)

    respond_to do |format|
      begin
        if @warehouse.save
          format.html { redirect_to @warehouse, notice: 'Warehouse was successfully created.' }
          format.json { render :show, status: :created, location: @warehouse }
        else
          format.html { render :new }
          format.json { render json: @warehouse.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        @warehouse.errors.messages[:code] = ["has already been taken"]
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /warehouses/1
  # PATCH/PUT /warehouses/1.json
  def update
    respond_to do |format|
      begin
        if @warehouse.update(warehouse_params)
          format.html { redirect_to @warehouse, notice: 'Warehouse was successfully updated.' }
          format.json { render :show, status: :ok, location: @warehouse }
        else
          format.html { render :edit }
          format.json { render json: @warehouse.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        @warehouse.errors.messages[:code] = ["has already been taken"]
        format.html { render :edit }
      end

    end
  end

  # DELETE /warehouses/1
  # DELETE /warehouses/1.json
  def destroy
    @warehouse.destroy
    if @warehouse.errors.present? and @warehouse.errors.messages[:base].present?
      alert = @warehouse.errors.messages[:base].to_sentence
    else
      notice = 'Warehouse was successfully deleted.'
    end
    respond_to do |format|
      format.html do 
        if notice.present?
          redirect_to warehouses_url, notice: notice
        else
          redirect_to warehouses_url, alert: alert
        end
      end
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_warehouse
    @warehouse = Warehouse.joins(:supervisor, :region, :price_code).where(id: params[:id]).
      select("warehouses.id, warehouses.code, warehouses.name, warehouses.address, is_active, supervisors.name AS supervisor_name, common_fields.code AS region_code, price_codes_warehouses.code AS price_code_code, warehouse_type, supervisor_id, region_id, price_code_id").first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def warehouse_params
    params.require(:warehouse).permit(:code, :name, :address, :is_active, :supervisor_id, :region_id, :warehouse_type, :price_code_id)
  end
end
