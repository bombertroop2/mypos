class GeneralVariablesController < ApplicationController
  authorize_resource
  before_action :set_general_variable, only: [:show, :edit, :update, :destroy]

  # GET /general_variables
  # GET /general_variables.json
  def index
    @general_variables = GeneralVariable.all
  end

  # GET /general_variables/1
  # GET /general_variables/1.json
  def show
  end

  # GET /general_variables/new
  def new
    if (gv = GeneralVariable.select(:id).first).blank?
      @general_variable = GeneralVariable.new
    else
      redirect_to edit_general_variable_url(gv.id)
    end
  end

  # GET /general_variables/1/edit
  def edit
  end

  # POST /general_variables
  # POST /general_variables.json
  def create
    if (gv = GeneralVariable.select(:id).first).blank?
      @general_variable = GeneralVariable.new(general_variable_params)

      respond_to do |format|
        if @general_variable.save
          format.html { redirect_to edit_general_variable_url(@general_variable), notice: 'General variable was successfully created.' }
          format.json { render :show, status: :created, location: @general_variable }
        else
          format.html { render :new }
          format.json { render json: @general_variable.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to edit_general_variable_url(gv.id)
    end
  end

  # PATCH/PUT /general_variables/1
  # PATCH/PUT /general_variables/1.json
  def update
    respond_to do |format|
      if @general_variable.update(general_variable_params)
        format.html { redirect_to edit_general_variable_url(@general_variable), notice: 'General variable was successfully updated.' }
        format.json { render :show, status: :ok, location: @general_variable }
      else
        format.html { render :edit }
        format.json { render json: @general_variable.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /general_variables/1
  # DELETE /general_variables/1.json
  def destroy
    @general_variable.destroy
    respond_to do |format|
      format.html { redirect_to general_variables_url, notice: 'General variable was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_general_variable
    @general_variable = GeneralVariable.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def general_variable_params
    params.require(:general_variable).permit(:pieces_per_koli)
  end
end
