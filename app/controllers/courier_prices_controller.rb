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

      courier_prices_scope = CourierPrice.select(:id, :effective_date, :price_type, :price, "couriers.code", "couriers.name", "cities.name AS city_name").joins(:courier, :city).where(["couriers.status = ?", "External"])
      courier_prices_scope = courier_prices_scope.where(["courier_id = ?", params[:filter_courier]]) if params[:filter_courier].present?
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
    end

    # POST /courier_prices
    # POST /courier_prices.json
    def create
      convert_price_to_numeric
      @courier_price = CourierPrice.new(courier_price_params)
      @courier_price.attr_add_price_from_menu_courier_price = true
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

    private
    
    def convert_price_to_numeric
      params[:courier_price][:price] = params[:courier_price][:price].gsub("Rp","").gsub(".","").gsub(",",".") if params[:courier_price][:price].present?
    end
  
    # Use callbacks to share common setup or constraints between actions.
    def set_courier_price
      @courier_price = CourierPrice.select(:id, :effective_date, :price_type, :price, :city_id, :courier_id, "couriers.code", "couriers.name", "cities.name AS city_name", "couriers.via", "couriers.unit").joins(:courier, :city).find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def courier_price_params
      if action_name.eql?("update")
        params.require(:courier_price).permit(:city_id, :effective_date, :price_type, :price)
      else
        params.require(:courier_price).permit(:courier_id, :city_id, :effective_date, :price_type, :price)
      end
    end
  end
