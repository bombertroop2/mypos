include SmartListing::Helper::ControllerExtensions
class Accounting::AccountSaldosController < ApplicationController
  helper SmartListing::Helper
  before_action :set_setting, only: [:edit, :update, :destroy]
  before_action :set_saldo


  def index
    @settings = AccountingAccountSaldo.filters(params[:q] || {})
    @years = AccountingAccountSaldo.years
    @settings = smart_listing_create(:settings, @settings, partial: 'listing', default_sort: {code: "ASC"})
  end

  def edit; end

  def update
    @setting.update(params_saldo)
  end


  private
  #
  
  def params_saldo
    params.require(:accounting_account_saldo).permit(:saldo)
  end

  def set_setting
    @setting = AccountingAccountSaldo.find(params[:id])
  end
  
  def set_saldo
    AccountingAccountSaldo.generate_year_saldo
  end
end
