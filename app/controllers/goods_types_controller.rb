include SmartListing::Helper::ControllerExtensions
class GoodsTypesController < ApplicationController
  before_action :set_goods_type, only: [:show, :edit, :update, :destroy]
  helper SmartListing::Helper

  # GET /goods_types
  # GET /goods_types.json
  def index
    like_command =  if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    goods_types_scope = GoodsType.select(:id, :code, :name, :description)
    goods_types_scope = goods_types_scope.where(["code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(goods_types_scope.where(["name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(goods_types_scope.where(["description #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @goods_types = smart_listing_create(:goods_types, goods_types_scope, partial: 'goods_types/listing', default_sort: {code: "asc"})
  end

  # GET /goods_types/1
  # GET /goods_types/1.json
  def show
  end

  # GET /goods_types/new
  def new
    @goods_type = GoodsType.new
  end

  # GET /goods_types/1/edit
  def edit
  end

  # POST /goods_types
  # POST /goods_types.json
  def create
    @goods_type = GoodsType.new(goods_type_params)

    begin
      @goods_type.save
    rescue ActiveRecord::RecordNotUnique => e
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{goods_types_url}'"
    end

  end

  # PATCH/PUT /goods_types/1
  # PATCH/PUT /goods_types/1.json
  def update
    begin        
      @goods_type.update(goods_type_params)
    rescue ActiveRecord::RecordNotUnique => e   
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{goods_types_url}'"
    end
  end

  # DELETE /goods_types/1
  # DELETE /goods_types/1.json
  def destroy
    @goods_type.destroy
    
    if @goods_type.errors.present? and @goods_type.errors.messages[:base].present?
      flash[:alert] = @goods_type.errors.messages[:base].to_sentence
      render js: "window.location = '#{goods_types_url}'"
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_goods_type
    @goods_type = GoodsType.where(id: params[:id]).select(:id, :code, :name, :description).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def goods_type_params
    params[:goods_type].permit(:code, :name, :description)
  end
end
