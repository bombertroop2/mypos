include SmartListing::Helper::ControllerExtensions
class DepartmentsController < ApplicationController
  helper SmartListing::Helper
  before_action :set_department, only: [:show, :edit, :update, :destroy]

  # GET /departments
  # GET /departments.json
  def index
    like_command = "ILIKE"
    departments_scope = Department.select(:id, :code, :name, :description)
    departments_scope = departments_scope.where(["code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(departments_scope.where(["name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(departments_scope.where(["description #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @departments = smart_listing_create(:departments, departments_scope, partial: 'departments/listing', default_sort: {code: "asc"})
  end

  # GET /departments/1
  # GET /departments/1.json
  def show
  end

  # GET /departments/new
  def new
    @department = Department.new
  end

  # GET /departments/1/edit
  def edit
  end

  # POST /departments
  # POST /departments.json
  def create
    @department = Department.new(department_params)
    begin
      @created = @department.save
    rescue ActiveRecord::RecordNotUnique => e
      @created = false
      @department.errors.messages[:code] = ["has already been taken"]
    end
  end

  # PATCH/PUT /departments/1
  # PATCH/PUT /departments/1.json
  def update
    begin
      @updated = @department.update(department_params)
    rescue ActiveRecord::RecordNotUnique => e
      @updated = false
      @department.errors.messages[:code] = ["has already been taken"]
    end
  end

  # DELETE /departments/1
  # DELETE /departments/1.json
  def destroy
    @department.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_department
      @department = Department.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def department_params
      params.require(:department).permit(:code, :name, :description)
    end
end
