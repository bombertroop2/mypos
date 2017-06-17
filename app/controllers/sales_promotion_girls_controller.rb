include SmartListing::Helper::ControllerExtensions
class SalesPromotionGirlsController < ApplicationController
  load_and_authorize_resource
  before_action :set_sales_promotion_girl, only: [:show, :edit, :update, :destroy]
  helper SmartListing::Helper

  # GET /sales_promotion_girls
  # GET /sales_promotion_girls.json
  def index
    like_command =  if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    spg_scope = SalesPromotionGirl.joins(:warehouse).select("sales_promotion_girls.id, identifier, sales_promotion_girls.name, phone, warehouses.code AS warehouse_code, mobile_phone")
    spg_scope = spg_scope.where(["identifier #{like_command} ?", "%"+params[:filter]+"%"]).
      or(spg_scope.where(["sales_promotion_girls.name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(spg_scope.where(["phone #{like_command} ?", "%"+params[:filter]+"%"])).
      or(spg_scope.where(["warehouses.code #{like_command} ?", "%"+params[:filter]+"%"])).
      or(spg_scope.where(["mobile_phone #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @sales_promotion_girls = smart_listing_create(:sales_promotion_girls, spg_scope, partial: 'sales_promotion_girls/listing', default_sort: {identifier: "asc"})
  end

  # GET /sales_promotion_girls/1
  # GET /sales_promotion_girls/1.json
  def show
  end

  # GET /sales_promotion_girls/new
  def new
    @sales_promotion_girl = SalesPromotionGirl.new
  end

  # GET /sales_promotion_girls/1/edit
  def edit
  end

  # POST /sales_promotion_girls
  # POST /sales_promotion_girls.json
  def create    
    params[:sales_promotion_girl][:mobile_phone] = params[:sales_promotion_girl][:mobile_phone].gsub("_","")
    @sales_promotion_girl = SalesPromotionGirl.new(sales_promotion_girl_params)
    begin
      if @sales_promotion_girl.save
        #          @sales_promotion_girl.build_user if @sales_promotion_girl.user.nil?
        #        else
        @new_warehouse_code = Warehouse.select(:code).where(id: params[:sales_promotion_girl][:warehouse_id]).first.code
      end
    rescue ActiveRecord::RecordNotUnique => e
      render js: "bootbox.alert({message: \"Something went wrong. Please try again\",size: 'small'});"
    end
  end

  # PATCH/PUT /sales_promotion_girls/1
  # PATCH/PUT /sales_promotion_girls/1.json
  def update
    params[:sales_promotion_girl][:mobile_phone] = params[:sales_promotion_girl][:mobile_phone].gsub("_","")
    if @sales_promotion_girl.update(sales_promotion_girl_params)
      @new_warehouse_code = Warehouse.select(:code).where(id: params[:sales_promotion_girl][:warehouse_id]).first.code
      #      else
      #        @sales_promotion_girl.build_user if @sales_promotion_girl.user.nil?
    end
  end

  # DELETE /sales_promotion_girls/1
  # DELETE /sales_promotion_girls/1.json
  def destroy
    @sales_promotion_girl.destroy    
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_sales_promotion_girl
    @sales_promotion_girl = SalesPromotionGirl.joins(:warehouse).where(id: params[:id]).
      select("sales_promotion_girls.id, identifier, sales_promotion_girls.name, sales_promotion_girls.address, gender, phone, province, warehouses.code AS warehouse_code, mobile_phone, warehouse_id, role").first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def sales_promotion_girl_params
    params.require(:sales_promotion_girl).permit(:gender, :name, :address, :phone, :role,
      :province, :warehouse_id, :mobile_phone, user_attributes: [:email, :password, :id])
  end
  
  
end
