class Accounting::JurnalTransctionsController < ApplicationController
  before_action :set_model
  # before_action :set_setting, only: [:edit, :update, :destroy]
  #

  def index
  end

  private
  #
  def set_model
    @setting_model = AccountingJurnalTransction.use_setting(params[:jurnals])
    @jurnals = AccountingJurnalTransction.jurnals(params[:jurnals], params[:showroom])
    @total = AccountingJurnalTransction.total(params[:jurnals], params[:showroom])
  end
end
