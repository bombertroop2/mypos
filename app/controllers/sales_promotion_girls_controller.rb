class SalesPromotionGirlsController < ApplicationController
  before_action :set_sales_promotion_girl, only: [:show, :edit, :update, :destroy]

  # GET /sales_promotion_girls
  # GET /sales_promotion_girls.json
  def index
    @sales_promotion_girls = SalesPromotionGirl.all
  end

  # GET /sales_promotion_girls/1
  # GET /sales_promotion_girls/1.json
  def show
  end

  # GET /sales_promotion_girls/new
  def new
    @sales_promotion_girl = SalesPromotionGirl.new
    @sales_promotion_girl.build_user
  end

  # GET /sales_promotion_girls/1/edit
  def edit
  end

  # POST /sales_promotion_girls
  # POST /sales_promotion_girls.json
  def create
    @sales_promotion_girl = SalesPromotionGirl.new(sales_promotion_girl_params)

    respond_to do |format|
      if @sales_promotion_girl.save
        format.html { redirect_to @sales_promotion_girl, notice: 'Sales promotion girl was successfully created.' }
        format.json { render :show, status: :created, location: @sales_promotion_girl }
      else
        @sales_promotion_girl.build_user if @sales_promotion_girl.user.nil?
        format.html { render :new }
        format.json { render json: @sales_promotion_girl.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sales_promotion_girls/1
  # PATCH/PUT /sales_promotion_girls/1.json
  def update
    respond_to do |format|
      if @sales_promotion_girl.update(sales_promotion_girl_params)
        format.html { redirect_to @sales_promotion_girl, notice: 'Sales promotion girl was successfully updated.' }
        format.json { render :show, status: :ok, location: @sales_promotion_girl }
      else
        format.html { render :edit }
        format.json { render json: @sales_promotion_girl.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sales_promotion_girls/1
  # DELETE /sales_promotion_girls/1.json
  def destroy
    @sales_promotion_girl.destroy
    respond_to do |format|
      format.html { redirect_to sales_promotion_girls_url, notice: 'Sales promotion girl was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_sales_promotion_girl
    @sales_promotion_girl = SalesPromotionGirl.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def sales_promotion_girl_params
    params.require(:sales_promotion_girl).permit(:gender, :identifier, :name, :address, :phone, :role,
      :province, :warehouse_id, :mobile_phone, user_attributes: [:email, :password, :spg_role])
  end
end
