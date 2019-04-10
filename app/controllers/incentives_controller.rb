class IncentivesController < ApplicationController
  before_action :set_incentive, only: [:show, :edit, :update, :destroy]

  # GET /incentives
  # GET /incentives.json
  def index
    @incentives = Incentive.all
  end

  # GET /incentives/1
  # GET /incentives/1.json
  def show
  end

  # GET /incentives/new
  def new
    @incentive = Incentive.new
  end

  # GET /incentives/1/edit
  def edit
  end

  # POST /incentives
  # POST /incentives.json
  def create
    @incentive = Incentive.new(incentive_params)

    respond_to do |format|
      if @incentive.save
        format.html { redirect_to @incentive, notice: 'Incentive was successfully created.' }
        format.json { render :show, status: :created, location: @incentive }
      else
        format.html { render :new }
        format.json { render json: @incentive.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /incentives/1
  # PATCH/PUT /incentives/1.json
  def update
    respond_to do |format|
      if @incentive.update(incentive_params)
        format.html { redirect_to @incentive, notice: 'Incentive was successfully updated.' }
        format.json { render :show, status: :ok, location: @incentive }
      else
        format.html { render :edit }
        format.json { render json: @incentive.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /incentives/1
  # DELETE /incentives/1.json
  def destroy
    @incentive.destroy
    respond_to do |format|
      format.html { redirect_to incentives_url, notice: 'Incentive was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_incentive
      @incentive = Incentive.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def incentive_params
      params.require(:incentive).permit(:warehouse_code, :warehouse_name, :transaction_date, :sales_promotion_girl_name, :transaction_number, :net_sales, :incentive, :quantity)
    end
end
