class GoodsTypesController < ApplicationController
  before_action :set_goods_type, only: [:show, :edit, :update, :destroy]

  # GET /goods_types
  # GET /goods_types.json
  def index
    @goods_types = GoodsType.select :id, :code, :name
  end

  # GET /goods_types/1
  # GET /goods_types/1.json
  def show
  end

  # GET /goods_types/new
  def new
    @goods_type = GoodsType.new
  end

  # GET /goods_types/1/edit
  def edit
  end

  # POST /goods_types
  # POST /goods_types.json
  def create
    @goods_type = GoodsType.new(goods_type_params)

    respond_to do |format|
      begin
        if @goods_type.save
          format.html { redirect_to @goods_type, notice: 'Goods type was successfully created.' }
          format.json { render :show, status: :created, location: @goods_type }
        else
          format.html { render :new }
          format.json { render json: @goods_type.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        @goods_type.errors.messages[:code] = ["has already been taken"]
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /goods_types/1
  # PATCH/PUT /goods_types/1.json
  def update
    respond_to do |format|
      begin
        if @goods_type.update(goods_type_params)
          format.html { redirect_to @goods_type, notice: 'Goods type was successfully updated.' }
          format.json { render :show, status: :ok, location: @goods_type }
        else
          format.html { render :edit }
          format.json { render json: @goods_type.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        @goods_type.errors.messages[:code] = ["has already been taken"]
        format.html { render :edit }
      end
    end
  end

  # DELETE /goods_types/1
  # DELETE /goods_types/1.json
  def destroy
    @goods_type.destroy
    if @goods_type.errors.present? and @goods_type.errors.messages[:base].present?
      alert = @goods_type.errors.messages[:base].to_sentence
    else
      notice = 'Goods type was successfully deleted.'
    end
    respond_to do |format|
      format.html do 
        if notice.present?
          redirect_to goods_types_url, notice: notice
        else
          redirect_to goods_types_url, alert: alert
        end
      end
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_goods_type
    @goods_type = GoodsType.where(id: params[:id]).select(:id, :code, :name, :description).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def goods_type_params
    params[:goods_type].permit(:code, :name, :description)
  end
end
