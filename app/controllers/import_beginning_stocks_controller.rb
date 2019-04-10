class ImportBeginningStocksController < ApplicationController
  authorize_resource class: BeginningStockProduct
    def new
    end

    def create
      if request.post?
        ImportBeginningStockJob.perform_later(params[:file].path, params[:import_date], Date.current.strftime("%d/%m/%Y"))
      end      
    end
  end
