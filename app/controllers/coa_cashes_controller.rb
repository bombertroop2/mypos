include SmartListing::Helper::ControllerExtensions
class CoaCashesController < ApplicationController
  authorize_resource
  helper SmartListing::Helper
  before_action :set_coa_cash, only: [:show, :edit, :update, :destroy]
  # GET /coa_cashes
  # GET /coa_cashes.json
  def index
    like_command = "ILIKE"
    coa_cashes_scope = CoaCash.joins(:coa).select("coa_cashes.*, coas.code, coas.name")
    coa_cashes_scope = coa_cashes_scope.where(["coas.code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(coa_cashes_scope.where(["coas.name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(coa_cashes_scope.where(["date #{like_command} ?", "%"+params[:filter]+"%"])).
      or(coa_cashes_scope.where(["value #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @coa_cashes = smart_listing_create(:coa_cashes, coa_cashes_scope, partial: 'coa_cashes/listing', default_sort: {"coas.code": "asc"})
  end

  # GET /coa_cashes/1
  # GET /coa_cashes/1.json
  def show
  end

  # GET /coa_cashes/new
  def new
    @coa_cash = CoaCash.new
  end

  # GET /coa_cashes/1/edit
  def edit
  end

  # POST /coa_cashes
  # POST /coa_cashes.json
  def create
    params[:coa_cash][:value] = params[:coa_cash][:value].gsub("Rp","").gsub(".","").gsub(",",".") if params[:coa_cash][:value].present?
    @coa_cash = CoaCash.new(coa_cash_params)
    begin
      @created = @coa_cash.save
      unless @created
        if @coa_cash.errors[:base].present?
          render js: "bootbox.alert({message: \"#{@coa_cash.errors[:base].join("<br/>")}\",size: 'small'});"
        end
      end
    rescue ActiveRecord::RecordNotUnique => e
      @created = false
      if e.message.include?("index_coa_cashes_on_date_and_coa_id")
        @coa_cash.errors.messages[:coa_id] = ["has already been taken"]
      else
        @coa_cash.errors.messages[:date] = ["has already been taken"]
      end
    end
  end

  # PATCH/PUT /coa_cashes/1
  # PATCH/PUT /coa_cashes/1.json
  def update
    params[:coa_cash][:value] = params[:coa_cash][:value].gsub("Rp","").gsub(".","").gsub(",",".") if params[:coa_cash][:value].present?
    begin
      @updated = @coa_cash.update(coa_cash_params)
    rescue ActiveRecord::RecordNotUnique => e
      @updated = false
      if e.message.include?("index_coa_cashes_on_date_and_coa_id")
        @coa_cash.errors.messages[:coa_id] = ["has already been taken"]
      else
        @coa_cash.errors.messages[:date] = ["has already been taken"]
      end
    end
  end

  # DELETE /coa_cashes/1
  # DELETE /coa_cashes/1.json
  def destroy
    @coa_cash.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_coa_cash
      @coa_cash = CoaCash.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def coa_cash_params
      params.require(:coa_cash).permit(:coa_id, :date, :value)
    end
end
