class GeneralLedgersController < ApplicationController

  def index
    respond_to do |format|
      if params[:transaction_date].present? && params[:transaction_type]
        splitted_date = params[:transaction_date].split(" - ")
        @general_ledgers = Journal.joins(:coa).where("journals.transaction_date" => splitted_date[0].to_date..splitted_date[1].to_date, "coas.transaction_type" => params[:transaction_type]).select("journals.transaction_date, coas.name, coas.transaction_type, SUM(journals.gross) AS Total").group("journals.transaction_date, coas.name, coas.transaction_type").order("journals.transaction_date")
        format.js
      end
      format.html
    end
  end

end
