include SmartListing::Helper::ControllerExtensions
class Accounting::AccountSettingsController < ApplicationController
  # authorize_resource
  helper SmartListing::Helper

  before_action :set_model
  before_action :set_setting, only: [:edit, :update, :destroy]

  def index
    @settings = @model.filters(params[:q] || {})
    @settings = smart_listing_create(:settings, @settings, partial: 'accounting/account_settings/listing', default_sort: {code: "ASC"})
  end

  def new
    @setting = @model.new
  end

  def create
    @setting = @model.new(params_setting)
    @setting.save
  end

  def edit; end

  def update
    @setting.update(params_setting)
  end

  def destroy
   @setting.destroy
  end

  private
  #
  def set_model
    @model = AccountingAccountSetting.jurnal(params[:jurnals])
  end

  def set_setting
   @setting = @model.find(params[:id])
  end

  def params_setting
    params.require("accounting_account_setting_#{params[:jurnals]}".to_sym).permit(:coa_id, :is_debit)
  end
end
