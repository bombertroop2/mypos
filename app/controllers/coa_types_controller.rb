include SmartListing::Helper::ControllerExtensions
class CoaTypesController < ApplicationController
  authorize_resource
  helper SmartListing::Helper
  before_action :set_coa_type, only: [:show, :edit, :update, :destroy]

  # GET /coa_types
  # GET /coa_types.json
  def index
    like_command = "ILIKE"
    coa_types_scope = CoaType.select(:id, :code, :name, :description)
    coa_types_scope = coa_types_scope.where(["code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(coa_types_scope.where(["name #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @coa_types = smart_listing_create(:coa_types, coa_types_scope, partial: 'coa_types/listing', default_sort: {code: "asc"})
  end

  # GET /coa_types/1
  # GET /coa_types/1.json
  def show
  end

  # GET /coa_types/new
  def new
    @coa_type = CoaType.new
  end

  # GET /coa_types/1/edit
  def edit
  end

  # POST /coa_types
  # POST /coa_types.json
  def create
    @coa_type = CoaType.new(coa_type_params)
    begin
      @created = @coa_type.save
    rescue ActiveRecord::RecordNotUnique => e
      @created = false
      @coa_type.errors.messages[:code] = ["has already been taken"]
    end
  end

  # PATCH/PUT /coa_types/1
  # PATCH/PUT /coa_types/1.json
  def update
   begin
      @updated = @coa_type.update(coa_type_params)
    rescue ActiveRecord::RecordNotUnique => e
      @updated = false
      @coa_type.errors.messages[:code] = ["has already been taken"]
    end
  end

  # DELETE /coa_types/1
  # DELETE /coa_types/1.json
  def destroy
    @coa_type.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_coa_type
      @coa_type = CoaType.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def coa_type_params
      params.require(:coa_type).permit(:code, :name, :description)
    end
end
