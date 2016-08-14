class AreaManagersController < ApplicationController
  before_action :set_area_manager, only: [:show, :edit, :update, :destroy]

  # GET /supervisors
  # GET /supervisors.json
  def index
    @supervisors = Supervisor.select :id, :code, :name, :email, :phone, :mobile_phone
  end

  # GET /supervisors/1
  # GET /supervisors/1.json
  def show
  end

  # GET /supervisors/new
  def new
    @supervisor = Supervisor.new
  end

  # GET /supervisors/1/edit
  def edit
  end

  # POST /supervisors
  # POST /supervisors.json
  def create
    @supervisor = Supervisor.new(area_manager_params)

    respond_to do |format|
      begin
        if @supervisor.save
          format.html { redirect_to area_manager_url(@supervisor), notice: 'Area Manager was successfully created.' }
          format.json { render :show, status: :created, location: @supervisor }
        else
          format.html { render :new }
          format.json { render json: @supervisor.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        if e.message.include? "supervisors.email"
          @supervisor.errors.messages[:email] = ["has already been taken"]
        else
          @supervisor.errors.messages[:code] = ["has already been taken"]
        end
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /supervisors/1
  # PATCH/PUT /supervisors/1.json
  def update
    respond_to do |format|
      begin
        if @supervisor.update(area_manager_params)
          format.html { redirect_to area_manager_url(@supervisor), notice: 'Area Manager was successfully updated.' }
          format.json { render :show, status: :ok, location: @supervisor }
        else
          format.html { render :edit }
          format.json { render json: @supervisor.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        if e.message.include? "column email is not unique"
          @supervisor.errors.messages[:email] = ["has already been taken"]
        else
          @supervisor.errors.messages[:code] = ["has already been taken"]
        end
        format.html { render :edit }
      end
    end
  end

  # DELETE /supervisors/1
  # DELETE /supervisors/1.json
  def destroy
    @supervisor.destroy
    if @supervisor.errors.present? and @supervisor.errors.messages[:base].present?
      alert = @supervisor.errors.messages[:base].to_sentence
    else
      notice = 'Area Manager was successfully deleted.'
    end
    respond_to do |format|
      format.html do 
        if notice.present?
          redirect_to area_managers_url, notice: notice
        else
          redirect_to area_managers_url, alert: alert
        end
      end
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_area_manager
    @supervisor = Supervisor.where(id: params[:id]).select(:id, :code, :name, :address, :email, :phone, :mobile_phone).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def area_manager_params
    params.require(:supervisor).permit(:code, :name, :address, :email, :phone, :mobile_phone)
  end
end
