include SmartListing::Helper::ControllerExtensions
class CourierPricesController < ApplicationController
  helper SmartListing::Helper
  authorize_resource class: Courier
    before_action :set_courier_price, only: [:show, :edit, :update, :destroy]

    # GET /courier_prices
    # GET /courier_prices.json
    def index
      if params[:filter_effective_date].present?
        splitted_effective_date_range = params[:filter_effective_date].split("-")
        start_effective_date = splitted_effective_date_range[0].strip.to_date
        end_effective_date = splitted_effective_date_range[1].strip.to_date
      end

      courier_prices_scope = CourierPrice.select(:id, :effective_date, :price_type, :price, "couriers.code", "couriers.name", "cities.name AS city_name").joins([courier_unit: [courier_way: :courier]], :city).where(["couriers.status = ?", "External"])
      courier_prices_scope = courier_prices_scope.where(["couriers.id = ?", params[:filter_courier]]) if params[:filter_courier].present?
      courier_prices_scope = courier_prices_scope.where(["city_id = ?", params[:filter_city]]) if params[:filter_city].present?
      courier_prices_scope = courier_prices_scope.where(["effective_date BETWEEN ? AND ?", start_effective_date, end_effective_date]) if params[:filter_effective_date].present?
      courier_prices_scope = courier_prices_scope.where(["price_type = ?", params[:filter_price_type]]) if params[:filter_price_type].present?
      smart_listing_create(:courier_prices, courier_prices_scope, partial: 'courier_prices/listing', default_sort: {effective_date: "desc"})
    end

    # GET /courier_prices/1
    # GET /courier_prices/1.json
    def show
    end

    # GET /courier_prices/new
    def new
      @courier_price = CourierPrice.new
    end

    # GET /courier_prices/1/edit
    def edit
      @courier_price.effective_date = @courier_price.effective_date.strftime("%d/%m/%Y")
      @courier_price.attr_courier_id = @courier_price.courier_id
      @courier_price.attr_courier_way_id = @courier_price.courier_way_id
    end

    # POST /courier_prices
    # POST /courier_prices.json
    def create
      convert_price_to_numeric
      @courier_price = CourierPrice.new(courier_price_params)
      @invalid = !@courier_price.save
    rescue ActiveRecord::RecordNotUnique => e
      render js: "bootbox.alert({message: 'Price should be unique!', size: 'small'})"
    end

    # PATCH/PUT /courier_prices/1
    # PATCH/PUT /courier_prices/1.json
    def update
      convert_price_to_numeric
      begin        
        unless @valid = @courier_price.update(courier_price_params)
          if @courier_price.errors[:base].present?
            render js: "bootbox.alert({message: \"#{@courier_price.errors[:base].join("<br/>")}\",size: 'small'});"
          end
        end
      rescue ActiveRecord::RecordNotUnique => e
        @valid = false
        @courier_price.errors.messages[:effective_date] = ["has already been taken"]
      end
    end

    # DELETE /courier_prices/1
    # DELETE /courier_prices/1.json
    def destroy
      unless @courier_price.destroy
        @deleted = false
      else
        @deleted = true
      end
    end
    
    def get_courier_ways
      @courier_ways = CourierWay.select(:id, :name).where(courier_id: params[:courier_id]).order(:name)
    end

    def get_courier_units
      @courier_units = CourierUnit.select(:id, :name).where(courier_way_id: params[:courier_way_id]).order(:name)
    end

    private
    
    def convert_price_to_numeric
      params[:courier_price][:price] = params[:courier_price][:price].gsub("Rp","").gsub(".","").gsub(",",".") if params[:courier_price][:price].present?
    end
  
    # Use callbacks to share common setup or constraints between actions.
    def set_courier_price
      @courier_price = CourierPrice.joins(:city, courier_unit: [courier_way: :courier]).select(:id, :effective_date, :price_type, :price, :city_id, :courier_unit_id, "couriers.code", "couriers.name", "cities.name AS city_name", "courier_ways.name AS via", "courier_units.name AS unit", "courier_ways.courier_id", "courier_units.courier_way_id").find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def courier_price_params
      params.require(:courier_price).permit(:city_id, :effective_date, :price_type, :price, :attr_courier_id, :attr_courier_way_id, :courier_unit_id)
    end
  end
