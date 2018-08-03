class GrowthReportsController < ApplicationController
  def index
    respond_to do |format|
      if params[:region].present?
        #        @warehouses = if params[:region].strip.eql?("0")
        #          Warehouse.
        #            select(:id, :code, :name, :region_id).
        #            select("common_fields.code AS region_code, common_fields.name AS region_name").
        #            joins(:region).
        #            counter.actived.where(["warehouses.counter_type = ?", params[:counter_type]]).order("common_fields.code ASC").group(:id, "common_fields.code, common_fields.name")
        #        else
        #          Warehouse.
        #            select(:id, :code, :name, :region_id).
        #            select("common_fields.code AS region_code, common_fields.name AS region_name").
        #            joins(:region).
        #            counter.actived.where(["warehouses.counter_type = ?", params[:counter_type]]).where(["common_fields.id = ?", params[:region].strip]).order("common_fields.code ASC").group(:id, "common_fields.code, common_fields.name")
        #        end
        if params[:date].present?
          prev_year_date = params[:date].to_date - 1.year
          selected_year_date = params[:date].to_date
          @warehouses = if params[:region].strip.eql?("0")
            Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              select("string_agg(CAST(CASE WHEN consignment_sales.transaction_date = '#{prev_year_date}' THEN consignment_sale_products.total ELSE 0 END AS VARCHAR(255)), ',') AS prev_net_sales").
              select("string_agg(CAST(CASE WHEN consignment_sales.transaction_date = '#{selected_year_date}' THEN consignment_sale_products.total ELSE 0 END AS VARCHAR(255)), ',') AS selected_net_sales").
              select("string_agg(CASE WHEN consignment_sales.transaction_date = '#{prev_year_date}' THEN '1' ELSE '0' END, ',') AS prev_qty_sold").
              select("string_agg(CASE WHEN consignment_sales.transaction_date = '#{selected_year_date}' THEN '1' ELSE '0' END, ',') AS selected_qty_sold").
              select("((transaction_detail.bs_quantity + transaction_detail.do_quantity + transaction_detail.rgi_quantity) - (transaction_detail.rw_quantity + transaction_detail.rgo_quantity + transaction_detail.slk_quantity)) AS ending_stock").
              joins(:region).
              joins("INNER JOIN consignment_sales ON consignment_sales.warehouse_id = warehouses.id AND consignment_sales.no_sale <> 't' AND (consignment_sales.transaction_date = '#{prev_year_date}' OR consignment_sales.transaction_date = '#{selected_year_date}')").
              joins("INNER JOIN consignment_sale_products ON consignment_sale_products.consignment_sale_id = consignment_sales.id").
              joins("LEFT JOIN (SELECT listing_stocks.warehouse_id, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'BS' THEN listing_stock_transactions.quantity ELSE 0 END) AS bs_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'DO' THEN listing_stock_transactions.quantity ELSE 0 END) AS do_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'RW' THEN listing_stock_transactions.quantity ELSE 0 END) AS rw_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'RGO' THEN listing_stock_transactions.quantity ELSE 0 END) AS rgo_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'RGI' THEN listing_stock_transactions.quantity ELSE 0 END) AS rgi_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'SLK' THEN listing_stock_transactions.quantity ELSE 0 END) AS slk_quantity FROM listing_stocks INNER JOIN listing_stock_product_details ON listing_stock_product_details.listing_stock_id = listing_stocks.id INNER JOIN listing_stock_transactions ON listing_stock_transactions.listing_stock_product_detail_id = listing_stock_product_details.id WHERE (listing_stock_transactions.transaction_date <= '#{selected_year_date}') GROUP BY listing_stocks.warehouse_id) AS transaction_detail ON transaction_detail.warehouse_id = warehouses.id").
              counter.actived.where(["warehouses.counter_type = ?", params[:counter_type]]).order("common_fields.code ASC").group(:id, "common_fields.code", "common_fields.name", "transaction_detail.bs_quantity", "transaction_detail.do_quantity", "transaction_detail.rgi_quantity", "transaction_detail.rw_quantity", "transaction_detail.rgo_quantity", "transaction_detail.slk_quantity")
          else
            Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              select("string_agg(CAST(CASE WHEN consignment_sales.transaction_date = '#{prev_year_date}' THEN consignment_sale_products.total ELSE 0 END AS VARCHAR(255)), ',') AS prev_net_sales").
              select("string_agg(CAST(CASE WHEN consignment_sales.transaction_date = '#{selected_year_date}' THEN consignment_sale_products.total ELSE 0 END AS VARCHAR(255)), ',') AS selected_net_sales").
              select("string_agg(CASE WHEN consignment_sales.transaction_date = '#{prev_year_date}' THEN '1' ELSE '0' END, ',') AS prev_qty_sold").
              select("string_agg(CASE WHEN consignment_sales.transaction_date = '#{selected_year_date}' THEN '1' ELSE '0' END, ',') AS selected_qty_sold").
              select("((transaction_detail.bs_quantity + transaction_detail.do_quantity + transaction_detail.rgi_quantity) - (transaction_detail.rw_quantity + transaction_detail.rgo_quantity + transaction_detail.slk_quantity)) AS ending_stock").
              joins(:region).
              joins("INNER JOIN consignment_sales ON consignment_sales.warehouse_id = warehouses.id AND consignment_sales.no_sale <> 't' AND (consignment_sales.transaction_date = '#{prev_year_date}' OR consignment_sales.transaction_date = '#{selected_year_date}')").
              joins("INNER JOIN consignment_sale_products ON consignment_sale_products.consignment_sale_id = consignment_sales.id").
              joins("LEFT JOIN (SELECT listing_stocks.warehouse_id, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'BS' THEN listing_stock_transactions.quantity ELSE 0 END) AS bs_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'DO' THEN listing_stock_transactions.quantity ELSE 0 END) AS do_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'RW' THEN listing_stock_transactions.quantity ELSE 0 END) AS rw_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'RGO' THEN listing_stock_transactions.quantity ELSE 0 END) AS rgo_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'RGI' THEN listing_stock_transactions.quantity ELSE 0 END) AS rgi_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'SLK' THEN listing_stock_transactions.quantity ELSE 0 END) AS slk_quantity FROM listing_stocks INNER JOIN listing_stock_product_details ON listing_stock_product_details.listing_stock_id = listing_stocks.id INNER JOIN listing_stock_transactions ON listing_stock_transactions.listing_stock_product_detail_id = listing_stock_product_details.id WHERE (listing_stock_transactions.transaction_date <= '#{selected_year_date}') GROUP BY listing_stocks.warehouse_id) AS transaction_detail ON transaction_detail.warehouse_id = warehouses.id").
              counter.actived.where(["warehouses.counter_type = ?", params[:counter_type]]).where(["common_fields.id = ?", params[:region].strip]).order("common_fields.code ASC").group(:id, "common_fields.code", "common_fields.name", "transaction_detail.bs_quantity", "transaction_detail.do_quantity", "transaction_detail.rgi_quantity", "transaction_detail.rw_quantity", "transaction_detail.rgo_quantity", "transaction_detail.slk_quantity")
          end
        elsif params[:month].present?
          prev_year_beginning_of_month = "1/#{params[:month]}/#{params[:year].to_i - 1}".to_date
          prev_year_end_of_month = prev_year_beginning_of_month.end_of_month
          selected_year_beginning_of_month = "1/#{params[:month]}/#{params[:year]}".to_date
          selected_year_end_of_month = selected_year_beginning_of_month.end_of_month
          @warehouses = if params[:region].strip.eql?("0")
            Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              select("string_agg(CAST(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_month}' THEN consignment_sale_products.total ELSE 0 END AS VARCHAR(255)), ',') AS prev_net_sales").
              select("string_agg(CAST(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_month}' THEN consignment_sale_products.total ELSE 0 END AS VARCHAR(255)), ',') AS selected_net_sales").
              select("string_agg(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_month}' THEN '1' ELSE '0' END, ',') AS prev_qty_sold").
              select("string_agg(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_month}' THEN '1' ELSE '0' END, ',') AS selected_qty_sold").
              joins(:region).
              joins("INNER JOIN consignment_sales ON consignment_sales.warehouse_id = warehouses.id AND consignment_sales.no_sale <> 't' AND ((consignment_sales.transaction_date >= '#{prev_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_month}') OR (consignment_sales.transaction_date >= '#{selected_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_month}'))").
              joins("INNER JOIN consignment_sale_products ON consignment_sale_products.consignment_sale_id = consignment_sales.id").
              counter.actived.where(["warehouses.counter_type = ?", params[:counter_type]]).order("common_fields.code ASC").group(:id, "common_fields.code", "common_fields.name")
          else
            Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              select("string_agg(CAST(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_month}' THEN consignment_sale_products.total ELSE 0 END AS VARCHAR(255)), ',') AS prev_net_sales").
              select("string_agg(CAST(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_month}' THEN consignment_sale_products.total ELSE 0 END AS VARCHAR(255)), ',') AS selected_net_sales").
              select("string_agg(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_month}' THEN '1' ELSE '0' END, ',') AS prev_qty_sold").
              select("string_agg(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_month}' THEN '1' ELSE '0' END, ',') AS selected_qty_sold").
              joins(:region).
              joins("INNER JOIN consignment_sales ON consignment_sales.warehouse_id = warehouses.id AND consignment_sales.no_sale <> 't' AND ((consignment_sales.transaction_date >= '#{prev_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_month}') OR (consignment_sales.transaction_date >= '#{selected_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_month}'))").
              joins("INNER JOIN consignment_sale_products ON consignment_sale_products.consignment_sale_id = consignment_sales.id").
              counter.actived.where(["warehouses.counter_type = ?", params[:counter_type]]).where(["common_fields.id = ?", params[:region].strip]).order("common_fields.code ASC").group(:id, "common_fields.code", "common_fields.name")
          end
        else
          prev_year_beginning_of_year = "1/1/#{params[:year].to_i - 1}".to_date
          prev_year_end_of_year = prev_year_beginning_of_year.end_of_year
          selected_year_beginning_of_year = "1/1/#{params[:year]}".to_date
          selected_year_end_of_year = selected_year_beginning_of_year.end_of_year
          @warehouses = if params[:region].strip.eql?("0")
            Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              select("string_agg(CAST(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_year}' THEN consignment_sale_products.total ELSE 0 END AS VARCHAR(255)), ',') AS prev_net_sales").
              select("string_agg(CAST(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_year}' THEN consignment_sale_products.total ELSE 0 END AS VARCHAR(255)), ',') AS selected_net_sales").
              select("string_agg(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_year}' THEN '1' ELSE '0' END, ',') AS prev_qty_sold").
              select("string_agg(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_year}' THEN '1' ELSE '0' END, ',') AS selected_qty_sold").
              joins(:region).
              joins("INNER JOIN consignment_sales ON consignment_sales.warehouse_id = warehouses.id AND consignment_sales.no_sale <> 't' AND ((consignment_sales.transaction_date >= '#{prev_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_year}') OR (consignment_sales.transaction_date >= '#{selected_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_year}'))").
              joins("INNER JOIN consignment_sale_products ON consignment_sale_products.consignment_sale_id = consignment_sales.id").
              counter.actived.where(["warehouses.counter_type = ?", params[:counter_type]]).order("common_fields.code ASC").group(:id, "common_fields.code", "common_fields.name")
          else
            Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              select("string_agg(CAST(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_year}' THEN consignment_sale_products.total ELSE 0 END AS VARCHAR(255)), ',') AS prev_net_sales").
              select("string_agg(CAST(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_year}' THEN consignment_sale_products.total ELSE 0 END AS VARCHAR(255)), ',') AS selected_net_sales").
              select("string_agg(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_year}' THEN '1' ELSE '0' END, ',') AS prev_qty_sold").
              select("string_agg(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_year}' THEN '1' ELSE '0' END, ',') AS selected_qty_sold").
              joins(:region).
              joins("INNER JOIN consignment_sales ON consignment_sales.warehouse_id = warehouses.id AND consignment_sales.no_sale <> 't' AND ((consignment_sales.transaction_date >= '#{prev_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_year}') OR (consignment_sales.transaction_date >= '#{selected_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_year}'))").
              joins("INNER JOIN consignment_sale_products ON consignment_sale_products.consignment_sale_id = consignment_sales.id").
              counter.actived.where(["warehouses.counter_type = ?", params[:counter_type]]).where(["common_fields.id = ?", params[:region].strip]).order("common_fields.code ASC").group(:id, "common_fields.code", "common_fields.name")
          end
        end
        format.js
      else
        format.html
      end
    end
  end
end
