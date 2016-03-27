class VendorsController < ApplicationController
  before_action :set_vendor, only: [:show, :edit, :update, :destroy]

  # GET /vendors
  # GET /vendors.json
  def index
    @vendors = Vendor.all
  end

  # GET /vendors/1
  # GET /vendors/1.json
  def show
  end

  # GET /vendors/new
  def new
    @vendor = Vendor.new
  end

  # GET /vendors/1/edit
  def edit
  end

  # POST /vendors
  # POST /vendors.json
  def create
    @vendor = Vendor.new(vendor_params)

    respond_to do |format|
      begin
        if @vendor.save
          format.html { redirect_to @vendor, notice: 'Vendor was successfully created.' }
          format.json { render :show, status: :created, location: @vendor }
        else
          format.html { render :new }
          format.json { render json: @vendor.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        @vendor.errors.messages[:code] = ["has already been taken"]
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /vendors/1
  # PATCH/PUT /vendors/1.json
  def update
    respond_to do |format|
      begin
        if @vendor.update(vendor_params)
          format.html { redirect_to @vendor, notice: 'Vendor was successfully updated.' }
          format.json { render :show, status: :ok, location: @vendor }
        else
          format.html { render :edit }
          format.json { render json: @vendor.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        @vendor.errors.messages[:code] = ["has already been taken"]
        format.html { render :edit }
      end
    end
  end

  # DELETE /vendors/1
  # DELETE /vendors/1.json
  def destroy
    @vendor.destroy
    if @vendor.errors.present? and @vendor.errors.messages[:base].present?
      alert = @vendor.errors.messages[:base].to_sentence
    else
      notice = 'Vendor was successfully deleted.'
    end
    respond_to do |format|
      format.html do 
        if notice.present?
          redirect_to vendors_url, notice: notice
        else
          redirect_to vendors_url, alert: alert
        end
      end
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_vendor
    @vendor = Vendor.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def vendor_params
    params.require(:vendor).permit(:terms_of_payment, :value_added_tax, :code, :name, :phone, :facsimile, :email, :pic_name, :pic_phone, :pic_mobile_phone, :pic_email, :address)
  end
end
