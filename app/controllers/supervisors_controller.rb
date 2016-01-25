class SupervisorsController < ApplicationController
  before_action :set_supervisor, only: [:show, :edit, :update, :destroy]

  # GET /supervisors
  # GET /supervisors.json
  def index
    @supervisors = Supervisor.all
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
    @supervisor = Supervisor.new(supervisor_params)

    respond_to do |format|
      begin
        if @supervisor.save
          format.html { redirect_to @supervisor, notice: 'Supervisor was successfully created.' }
          format.json { render :show, status: :created, location: @supervisor }
        else
          format.html { render :new }
          format.json { render json: @supervisor.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        if e.message.include? "column email is not unique"        
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
        if @supervisor.update(supervisor_params)
          format.html { redirect_to @supervisor, notice: 'Supervisor was successfully updated.' }
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
    message = if @supervisor.errors.present? and @supervisor.errors.messages[:base].present?
      @supervisor.errors.messages[:base].to_sentence
    else
      'Supervisor was successfully destroyed.'
    end
    respond_to do |format|
      format.html { redirect_to supervisors_url, notice: message }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_supervisor
    @supervisor = Supervisor.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def supervisor_params
    params.require(:supervisor).permit(:code, :name, :address, :email, :phone, :mobile_phone)
  end
end
