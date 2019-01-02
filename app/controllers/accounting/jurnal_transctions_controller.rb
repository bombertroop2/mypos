class Accounting::JurnalTransctionsController < ApplicationController
  before_action :set_model
  # before_action :set_setting, only: [:edit, :update, :destroy]
  #

  def index
  end

  private
  #
  def set_model
    year = params[:date].present? && params_date ? params[:date][:year].to_i : Date.today.year
    month = params[:date].present? && params_date ? Date::MONTHNAMES.index(params[:date][:month]) : Date.today.month
    @setting_model = AccountingJurnalTransction.use_setting(params[:jurnals])
    @jurnals = AccountingJurnalTransction.jurnals(params[:jurnals], params[:showroom], year, month)
    @total = AccountingJurnalTransction.total(params[:jurnals], params[:showroom], year, month)
    @start_year = AccountingJurnalTransction.start_year
  end

  def params_date
    params.require(:date).permit(:year, :month)
  end
end
