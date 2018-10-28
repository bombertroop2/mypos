class QuantitySoldChartsController < ApplicationController
  authorize_resource
  def index
    respond_to do |format|
      if params[:region].present? && params[:year].present? && params[:counter_type].present? && params[:brand].present?
        if params[:region].strip.eql?("0")
          @region_name = "All"
        else
          region = Region.select(:name).find(params[:region].strip)
          @region_name = region.name
        end
        brand = Brand.select(:id, :name).find(params[:brand].strip)
        @brand_name = brand.name
        @counter_type = params[:counter_type].strip
        @models = Model.select(:id, :name).order(:name)
        beginning_date_jan = "1/1/#{params[:year].strip}".to_date
        end_date_jan = beginning_date_jan.end_of_month
        beginning_date_feb = "1/2/#{params[:year].strip}".to_date
        end_date_feb = beginning_date_feb.end_of_month
        beginning_date_mar = "1/3/#{params[:year].strip}".to_date
        end_date_mar = beginning_date_mar.end_of_month
        beginning_date_apr = "1/4/#{params[:year].strip}".to_date
        end_date_apr = beginning_date_apr.end_of_month
        beginning_date_may = "1/5/#{params[:year].strip}".to_date
        end_date_may = beginning_date_may.end_of_month
        beginning_date_jun = "1/6/#{params[:year].strip}".to_date
        end_date_jun = beginning_date_jun.end_of_month
        beginning_date_jul = "1/7/#{params[:year].strip}".to_date
        end_date_jul = beginning_date_jul.end_of_month
        beginning_date_aug = "1/8/#{params[:year].strip}".to_date
        end_date_aug = beginning_date_aug.end_of_month
        beginning_date_sep = "1/9/#{params[:year].strip}".to_date
        end_date_sep = beginning_date_sep.end_of_month
        beginning_date_oct = "1/10/#{params[:year].strip}".to_date
        end_date_oct = beginning_date_oct.end_of_month
        beginning_date_nov = "1/11/#{params[:year].strip}".to_date
        end_date_nov = beginning_date_nov.end_of_month
        beginning_date_dec = "1/12/#{params[:year].strip}".to_date
        end_date_dec = beginning_date_dec.end_of_month
        @consignment_sale_products = if params[:region].strip.eql?("0")
          ConsignmentSaleProduct.
            select("model_id").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_jan}' AND consignment_sales.transaction_date <= '#{end_date_jan}' THEN 1 ELSE 0 END) AS qty_sold_jan").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_feb}' AND consignment_sales.transaction_date <= '#{end_date_feb}' THEN 1 ELSE 0 END) AS qty_sold_feb").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_mar}' AND consignment_sales.transaction_date <= '#{end_date_mar}' THEN 1 ELSE 0 END) AS qty_sold_mar").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_apr}' AND consignment_sales.transaction_date <= '#{end_date_apr}' THEN 1 ELSE 0 END) AS qty_sold_apr").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_may}' AND consignment_sales.transaction_date <= '#{end_date_may}' THEN 1 ELSE 0 END) AS qty_sold_may").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_jun}' AND consignment_sales.transaction_date <= '#{end_date_jun}' THEN 1 ELSE 0 END) AS qty_sold_jun").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_jul}' AND consignment_sales.transaction_date <= '#{end_date_jul}' THEN 1 ELSE 0 END) AS qty_sold_jul").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_aug}' AND consignment_sales.transaction_date <= '#{end_date_aug}' THEN 1 ELSE 0 END) AS qty_sold_aug").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_sep}' AND consignment_sales.transaction_date <= '#{end_date_sep}' THEN 1 ELSE 0 END) AS qty_sold_sep").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_oct}' AND consignment_sales.transaction_date <= '#{end_date_oct}' THEN 1 ELSE 0 END) AS qty_sold_oct").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_nov}' AND consignment_sales.transaction_date <= '#{end_date_nov}' THEN 1 ELSE 0 END) AS qty_sold_nov").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_dec}' AND consignment_sales.transaction_date <= '#{end_date_dec}' THEN 1 ELSE 0 END) AS qty_sold_dec").
            joins(consignment_sale: :warehouse).
            joins(product_barcode: [product_color: :product]).
            where(:"products.model_id" => @models.map(&:id)).
            where(:"products.brand_id" => params[:brand].strip).
            where(:"warehouses.counter_type" => params[:counter_type].strip).
            group("model_id")
        else
          ConsignmentSaleProduct.
            select("model_id").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_jan}' AND consignment_sales.transaction_date <= '#{end_date_jan}' THEN 1 ELSE 0 END) AS qty_sold_jan").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_feb}' AND consignment_sales.transaction_date <= '#{end_date_feb}' THEN 1 ELSE 0 END) AS qty_sold_feb").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_mar}' AND consignment_sales.transaction_date <= '#{end_date_mar}' THEN 1 ELSE 0 END) AS qty_sold_mar").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_apr}' AND consignment_sales.transaction_date <= '#{end_date_apr}' THEN 1 ELSE 0 END) AS qty_sold_apr").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_may}' AND consignment_sales.transaction_date <= '#{end_date_may}' THEN 1 ELSE 0 END) AS qty_sold_may").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_jun}' AND consignment_sales.transaction_date <= '#{end_date_jun}' THEN 1 ELSE 0 END) AS qty_sold_jun").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_jul}' AND consignment_sales.transaction_date <= '#{end_date_jul}' THEN 1 ELSE 0 END) AS qty_sold_jul").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_aug}' AND consignment_sales.transaction_date <= '#{end_date_aug}' THEN 1 ELSE 0 END) AS qty_sold_aug").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_sep}' AND consignment_sales.transaction_date <= '#{end_date_sep}' THEN 1 ELSE 0 END) AS qty_sold_sep").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_oct}' AND consignment_sales.transaction_date <= '#{end_date_oct}' THEN 1 ELSE 0 END) AS qty_sold_oct").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_nov}' AND consignment_sales.transaction_date <= '#{end_date_nov}' THEN 1 ELSE 0 END) AS qty_sold_nov").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_dec}' AND consignment_sales.transaction_date <= '#{end_date_dec}' THEN 1 ELSE 0 END) AS qty_sold_dec").
            joins(consignment_sale: :warehouse).
            joins(product_barcode: [product_color: :product]).
            where(:"products.model_id" => @models.map(&:id)).
            where(:"products.brand_id" => params[:brand].strip).
            where(:"warehouses.region_id" => params[:region].strip).
            where(:"warehouses.counter_type" => params[:counter_type].strip).
            group("model_id")
        end
        format.js
      else
        format.html
      end
    end
  end
end
