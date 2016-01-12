class SalesPromotionGirlsController < ApplicationController
  before_action :set_sales_promotion_girl, only: [:show, :edit, :update, :destroy]
  skip_before_action :is_user_can_cud?

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
    if user_is_not_cashier
      @sales_promotion_girl = SalesPromotionGirl.new
      @sales_promotion_girl.build_user
    else
      flash[:alert] = "Sorry, you can't access this request!"
      redirect_to :back rescue redirect_to root_url
    end
  end

  # GET /sales_promotion_girls/1/edit
  def edit
    if user_can_edit
      @sales_promotion_girl.build_user if @sales_promotion_girl.user.nil?
    else
      flash[:alert] = "Sorry, you can't access this request!"
      redirect_to :back rescue redirect_to root_url 
    end
  end

  # POST /sales_promotion_girls
  # POST /sales_promotion_girls.json
  def create
    if user_is_not_cashier
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
    else
      flash[:alert] = "Sorry, you can't access this request!"
      redirect_to :back rescue redirect_to root_url
    end
  end

  # PATCH/PUT /sales_promotion_girls/1
  # PATCH/PUT /sales_promotion_girls/1.json
  def update
    if user_can_edit
      respond_to do |format|
        if @sales_promotion_girl.update(sales_promotion_girl_params)
          format.html { redirect_to @sales_promotion_girl, notice: 'Sales promotion girl was successfully updated.' }
          format.json { render :show, status: :ok, location: @sales_promotion_girl }
        else
          @sales_promotion_girl.build_user if @sales_promotion_girl.user.nil?
          format.html { render :edit }
          format.json { render json: @sales_promotion_girl.errors, status: :unprocessable_entity }
        end
      end
    else
      flash[:alert] = "Sorry, you can't access this request!"
      redirect_to :back rescue redirect_to root_url 
    end
  end

  # DELETE /sales_promotion_girls/1
  # DELETE /sales_promotion_girls/1.json
  def destroy
    if user_is_not_cashier
      @sales_promotion_girl.destroy
      respond_to do |format|
        format.html { redirect_to sales_promotion_girls_url, notice: 'Sales promotion girl was successfully destroyed.' }
        format.json { head :no_content }
      end
    else
      flash[:alert] = "Sorry, you can't access this request!"
      redirect_to :back rescue redirect_to root_url 
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
  
  def user_can_edit
    if user_signed_in?
      user_role = current_user.roles.first.name
      if user_role.eql?("cashier")
        return false unless current_user.has_role? user_role.to_sym, @sales_promotion_girl
      elsif user_role.eql?("supervisor")
        unless @sales_promotion_girl.role.eql?("cashier")
          return false unless current_user.has_role? user_role.to_sym, @sales_promotion_girl
        end
      end
    end
    
    true
  end
  
  def user_is_not_cashier
    current_user.has_role?(:supervisor) || current_user.has_role?(:admin)
  end
end
