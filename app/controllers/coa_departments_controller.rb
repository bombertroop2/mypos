include SmartListing::Helper::ControllerExtensions
class CoaDepartmentsController < ApplicationController
  authorize_resource
  helper SmartListing::Helper
  before_action :set_coa_department, only: [:show, :edit, :update, :destroy]

  # GET /coa_departments
  # GET /coa_departments.json
  def index
    like_command = "ILIKE"
    coa_departments_scope = CoaDepartment.joins(:department,:coa,:warehouse).select("coa_departments.*, departments.code AS department_code, departments.name AS department_name, coas.code AS coa_code, coas.name AS coa_name, warehouses.code AS warhouse_code, warehouses.name AS warehouse_code")
    coa_departments_scope = coa_departments_scope.where(["departments.code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(coa_departments_scope.where(["departments.name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(coa_departments_scope.where(["coas.code #{like_command} ?", "%"+params[:filter]+"%"])).
      or(coa_departments_scope.where(["coas.name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(coa_departments_scope.where(["warehouses.code #{like_command} ?", "%"+params[:filter]+"%"])).
      or(coa_departments_scope.where(["warehouses.name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(coa_departments_scope.where(["coa_departments.location #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @coa_departments = smart_listing_create(:coa_departments, coa_departments_scope, partial: 'coa_departments/listing', default_sort: {id: "asc"})
  end

  # GET /coa_departments/1
  # GET /coa_departments/1.json
  def show
  end

  # GET /coa_departments/new
  def new
    @coa_department = CoaDepartment.new
  end

  # GET /coa_departments/1/edit
  def edit
  end

  # POST /coa_departments
  # POST /coa_departments.json
  def create
    @coa_department = CoaDepartment.new(coa_department_params)
    begin
      @created = @coa_department.save
    rescue ActiveRecord::RecordNotUnique => e
      @created = false
      @coa_department.errors.messages[:coa_id] = ["has already been taken"]
    end
  end

  # PATCH/PUT /coa_departments/1
  # PATCH/PUT /coa_departments/1.json
  def update
    begin
      @updated = @coa_department.update(coa_department_params)
    rescue ActiveRecord::RecordNotUnique => e
      @updated = false
      @coa_department.errors.messages[:coa_id] = ["has already been taken"]
    end
  end

  # DELETE /coa_departments/1
  # DELETE /coa_departments/1.json
  def destroy
    @coa_department.destroy
  end

  # def get_coa_department
  #   @coas = Coa.where(company_id: params[:id])
  #   @departments = Department.where(company_id: params[:id])
  #   respond_to do |format|
  #     format.js
  #   end
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_coa_department
      @coa_department = CoaDepartment.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def coa_department_params
      params.require(:coa_department).permit(:department_id, :coa_id, :warehouse_id, :location)
    end
end
