class GrowthReportsController < ApplicationController
  def index
    respond_to do |format|
      if params[:month].present? && params[:year].present? && params[:counter_type].present?
        prev_year_beginning_of_month = "1/#{params[:month]}/#{params[:year].to_i - 1}".to_date
        prev_year_end_of_month = prev_year_beginning_of_month.end_of_month
        selected_year_beginning_of_month = "1/#{params[:month]}/#{params[:year]}".to_date
        selected_year_end_of_month = selected_year_beginning_of_month.end_of_month
        @warehouses = if params[:region].strip.eql?("0")
          #                    Warehouse.
          #                      select(:id, :code, :name, :region_id).
          #                      select("common_fields.code AS region_code, common_fields.name AS region_name").
          #                      select("(SELECT SUM(consignment_sales.total) FROM consignment_sales WHERE (approved <> 't' AND warehouse_id = warehouses.id AND transaction_date >= '#{prev_year_beginning_of_month}' AND transaction_date <= '#{prev_year_end_of_month}')) AS prev_net_sales").
          #                      select("(SELECT SUM(consignment_sales.total) FROM consignment_sales WHERE (approved <> 't' AND warehouse_id = warehouses.id AND transaction_date >= '#{selected_year_beginning_of_month}' AND transaction_date <= '#{selected_year_end_of_month}')) AS selected_net_sales").
          #                      select("(SELECT SUM(1) FROM consignment_sale_products INNER JOIN consignment_sales ON consignment_sales.id = consignment_sale_products.consignment_sale_id WHERE (consignment_sales.transaction_date >= '#{prev_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_month}' AND consignment_sales.warehouse_id = warehouses.id AND consignment_sales.approved <> 't')) AS prev_qty_sold").
          #                      select("(SELECT SUM(1) FROM consignment_sale_products INNER JOIN consignment_sales ON consignment_sales.id = consignment_sale_products.consignment_sale_id WHERE (consignment_sales.transaction_date >= '#{selected_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_month}' AND consignment_sales.warehouse_id = warehouses.id AND consignment_sales.approved <> 't')) AS selected_qty_sold").
          #                      joins(:region).
          #                      counter.actived.where(["warehouses.counter_type = ?", params[:counter_type]]).order("common_fields.code ASC")
          Warehouse.
            select(:id, :code, :name, :region_id).
            select("common_fields.code AS region_code, common_fields.name AS region_name").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_month}' THEN consignment_sales.total ELSE 0 END) AS prev_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_month}' THEN consignment_sales.total ELSE 0 END) AS selected_net_sales").
            select("SUM(cs_qty_sold.prev_qty_sold_per_trans) AS prev_qty_sold, SUM(cs_qty_sold.selected_qty_sold_per_trans) AS selected_qty_sold").
            select("((transaction_detail.bs_quantity + transaction_detail.do_quantity  + transaction_detail.rgi_quantity) - (transaction_detail.rw_quantity + transaction_detail.rgo_quantity + transaction_detail.slk_quantity)) AS ending_stock").
            joins(:region).
            joins("INNER JOIN consignment_sales ON consignment_sales.warehouse_id = warehouses.id AND consignment_sales.no_sale <> 't' AND ((consignment_sales.transaction_date >= '#{prev_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_month}') OR (consignment_sales.transaction_date >= '#{selected_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_month}'))").
            joins("LEFT JOIN (SELECT csqs.id, SUM(CASE WHEN csqs.transaction_date >= '#{prev_year_beginning_of_month}' AND csqs.transaction_date <= '#{prev_year_end_of_month}' THEN 1 ELSE 0 END) AS prev_qty_sold_per_trans, SUM(CASE WHEN csqs.transaction_date >= '#{selected_year_beginning_of_month}' AND csqs.transaction_date <= '#{selected_year_end_of_month}' THEN 1 ELSE 0 END) AS selected_qty_sold_per_trans FROM consignment_sale_products INNER JOIN consignment_sales csqs ON csqs.id = consignment_sale_products.consignment_sale_id GROUP BY csqs.id) AS cs_qty_sold ON cs_qty_sold.id = consignment_sales.id").
            joins("LEFT JOIN (SELECT listing_stocks.warehouse_id, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'BS' THEN listing_stock_transactions.quantity ELSE 0 END) AS bs_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'DO' THEN listing_stock_transactions.quantity ELSE 0 END) AS do_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'RW' THEN listing_stock_transactions.quantity ELSE 0 END) AS rw_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'RGO' THEN listing_stock_transactions.quantity ELSE 0 END) AS rgo_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'RGI' THEN listing_stock_transactions.quantity ELSE 0 END) AS rgi_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'SLK' THEN listing_stock_transactions.quantity ELSE 0 END) AS slk_quantity FROM listing_stocks LEFT JOIN listing_stock_product_details ON listing_stock_product_details.listing_stock_id = listing_stocks.id LEFT JOIN listing_stock_transactions ON listing_stock_transactions.listing_stock_product_detail_id = listing_stock_product_details.id WHERE listing_stock_transactions.transaction_date <= '#{selected_year_end_of_month}' GROUP BY listing_stocks.warehouse_id) AS transaction_detail ON transaction_detail.warehouse_id = warehouses.id").
            counter.actived.where(["warehouses.counter_type = ?", params[:counter_type]]).order("common_fields.code ASC").group(:id)
        else
          #                                                  Warehouse.
          #                                                    select(:id, :code, :name, :region_id).
          #                                                    select("common_fields.code AS region_code, common_fields.name AS region_name").
          #                                                    select("(SELECT SUM(consignment_sales.total) FROM consignment_sales WHERE (approved <> 't' AND warehouse_id = warehouses.id AND transaction_date >= '#{prev_year_beginning_of_month}' AND transaction_date <= '#{prev_year_end_of_month}')) AS prev_net_sales").
          #                                                    select("(SELECT SUM(consignment_sales.total) FROM consignment_sales WHERE (approved <> 't' AND warehouse_id = warehouses.id AND transaction_date >= '#{selected_year_beginning_of_month}' AND transaction_date <= '#{selected_year_end_of_month}')) AS selected_net_sales").
          #                                                    select("(SELECT SUM(1) FROM consignment_sale_products INNER JOIN consignment_sales ON consignment_sales.id = consignment_sale_products.consignment_sale_id WHERE (consignment_sales.transaction_date >= '#{prev_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_month}' AND consignment_sales.warehouse_id = warehouses.id AND consignment_sales.approved <> 't')) AS prev_qty_sold").
          #                                                    select("(SELECT SUM(1) FROM consignment_sale_products INNER JOIN consignment_sales ON consignment_sales.id = consignment_sale_products.consignment_sale_id WHERE (consignment_sales.transaction_date >= '#{selected_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_month}' AND consignment_sales.warehouse_id = warehouses.id AND consignment_sales.approved <> 't')) AS selected_qty_sold").
          #                                                    joins(:region).
          #                                                    counter.actived.where(["warehouses.counter_type = ?", params[:counter_type]]).where(["common_fields.id = ?", params[:region].strip]).order("common_fields.code ASC")
          Warehouse.
            select(:id, :code, :name, :region_id).
            select("common_fields.code AS region_code, common_fields.name AS region_name").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_month}' THEN consignment_sales.total ELSE 0 END) AS prev_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_month}' THEN consignment_sales.total ELSE 0 END) AS selected_net_sales").
            select("SUM(cs_qty_sold.prev_qty_sold_per_trans) AS prev_qty_sold, SUM(cs_qty_sold.selected_qty_sold_per_trans) AS selected_qty_sold").
            select("((transaction_detail.bs_quantity + transaction_detail.do_quantity  + transaction_detail.rgi_quantity) - (transaction_detail.rw_quantity + transaction_detail.rgo_quantity + transaction_detail.slk_quantity)) AS ending_stock").
            joins(:region).
            joins("INNER JOIN consignment_sales ON consignment_sales.warehouse_id = warehouses.id AND consignment_sales.no_sale <> 't' AND ((consignment_sales.transaction_date >= '#{prev_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_month}') OR (consignment_sales.transaction_date >= '#{selected_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_month}'))").
            joins("LEFT JOIN (SELECT csqs.id, SUM(CASE WHEN csqs.transaction_date >= '#{prev_year_beginning_of_month}' AND csqs.transaction_date <= '#{prev_year_end_of_month}' THEN 1 ELSE 0 END) AS prev_qty_sold_per_trans, SUM(CASE WHEN csqs.transaction_date >= '#{selected_year_beginning_of_month}' AND csqs.transaction_date <= '#{selected_year_end_of_month}' THEN 1 ELSE 0 END) AS selected_qty_sold_per_trans FROM consignment_sale_products INNER JOIN consignment_sales csqs ON csqs.id = consignment_sale_products.consignment_sale_id GROUP BY csqs.id) AS cs_qty_sold ON cs_qty_sold.id = consignment_sales.id").
            joins("LEFT JOIN (SELECT listing_stocks.warehouse_id, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'BS' THEN listing_stock_transactions.quantity ELSE 0 END) AS bs_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'DO' THEN listing_stock_transactions.quantity ELSE 0 END) AS do_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'RW' THEN listing_stock_transactions.quantity ELSE 0 END) AS rw_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'RGO' THEN listing_stock_transactions.quantity ELSE 0 END) AS rgo_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'RGI' THEN listing_stock_transactions.quantity ELSE 0 END) AS rgi_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'SLK' THEN listing_stock_transactions.quantity ELSE 0 END) AS slk_quantity FROM listing_stocks LEFT JOIN listing_stock_product_details ON listing_stock_product_details.listing_stock_id = listing_stocks.id LEFT JOIN listing_stock_transactions ON listing_stock_transactions.listing_stock_product_detail_id = listing_stock_product_details.id WHERE listing_stock_transactions.transaction_date <= '#{selected_year_end_of_month}' GROUP BY listing_stocks.warehouse_id) AS transaction_detail ON transaction_detail.warehouse_id = warehouses.id").
            counter.actived.where(["warehouses.counter_type = ?", params[:counter_type]]).where(["common_fields.id = ?", params[:region].strip]).order("common_fields.code ASC").group(:id)
        end
        format.js
      elsif params[:date].present?
        prev_year_date = params[:date].to_date - 1.year
        selected_year_date = params[:date].to_date
        @warehouses = if params[:region].strip.eql?("0")
          #          Warehouse.
          #            select(:id, :code, :name, :region_id).
          #            select("common_fields.code AS region_code, common_fields.name AS region_name").
          #            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{prev_year_date}' THEN consignment_sale_products.total ELSE 0 END) AS prev_net_sales").
          #            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{selected_year_date}' THEN consignment_sale_products.total ELSE 0 END) AS selected_net_sales").
          #            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{prev_year_date}' THEN 1 ELSE 0 END) AS prev_qty_sold").
          #            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{selected_year_date}' THEN 1 ELSE 0 END) AS selected_qty_sold").
          #            select("((transaction_detail.bs_quantity + transaction_detail.do_quantity + transaction_detail.rgi_quantity) - (transaction_detail.rw_quantity + transaction_detail.rgo_quantity + transaction_detail.slk_quantity)) AS ending_stock").
          #            joins(:region).
          #            joins("INNER JOIN consignment_sales ON consignment_sales.warehouse_id = warehouses.id AND consignment_sales.no_sale <> 't' AND (consignment_sales.transaction_date = '#{prev_year_date}' OR consignment_sales.transaction_date = '#{selected_year_date}')").
          #            joins("INNER JOIN consignment_sale_products ON consignment_sale_products.consignment_sale_id = consignment_sales.id").
          #            joins("INNER JOIN product_barcodes ON product_barcodes.id = consignment_sale_products.product_barcode_id").
          #            joins("INNER JOIN product_colors ON product_colors.id = product_barcodes.product_color_id").
          #            joins("INNER JOIN listing_stock_product_details ON listing_stock_product_details.color_id = product_colors.color_id AND listing_stock_product_details.size_id = product_barcodes.size_id").
          #            joins("INNER JOIN listing_stocks ON listing_stocks.id = listing_stock_product_details.listing_stock_id AND listing_stocks.warehouse_id = warehouses.id AND listing_stocks.product_id = product_colors.product_id").
          #            joins("LEFT JOIN (SELECT listing_stocks.warehouse_id, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'BS' THEN listing_stock_transactions.quantity ELSE 0 END) AS bs_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'DO' THEN listing_stock_transactions.quantity ELSE 0 END) AS do_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'RW' THEN listing_stock_transactions.quantity ELSE 0 END) AS rw_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'RGO' THEN listing_stock_transactions.quantity ELSE 0 END) AS rgo_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'RGI' THEN listing_stock_transactions.quantity ELSE 0 END) AS rgi_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'SLK' THEN listing_stock_transactions.quantity ELSE 0 END) AS slk_quantity FROM listing_stocks INNER JOIN listing_stock_product_details ON listing_stock_product_details.listing_stock_id = listing_stocks.id INNER JOIN listing_stock_transactions ON listing_stock_transactions.listing_stock_product_detail_id = listing_stock_product_details.id WHERE (listing_stock_transactions.transaction_date <= '#{selected_year_date}') GROUP BY listing_stocks.warehouse_id) AS transaction_detail ON transaction_detail.warehouse_id = warehouses.id").
          #            counter.actived.where(["warehouses.counter_type = ?", params[:counter_type]]).order("common_fields.code ASC").group(:id)
          Warehouse.
            select(:id, :code, :name, :region_id).
            select("common_fields.code AS region_code, common_fields.name AS region_name").
            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{prev_year_date}' THEN consignment_sale_products.total ELSE 0 END) AS prev_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{selected_year_date}' THEN consignment_sale_products.total ELSE 0 END) AS selected_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{prev_year_date}' THEN 1 ELSE 0 END) AS prev_qty_sold").
            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{selected_year_date}' THEN 1 ELSE 0 END) AS selected_qty_sold").
            joins(:region).
            joins("INNER JOIN consignment_sales ON consignment_sales.warehouse_id = warehouses.id AND consignment_sales.no_sale <> 't' AND (consignment_sales.transaction_date = '#{prev_year_date}' OR consignment_sales.transaction_date = '#{selected_year_date}')").
            joins("INNER JOIN consignment_sale_products ON consignment_sale_products.consignment_sale_id = consignment_sales.id").
            #            joins("INNER JOIN product_barcodes ON product_barcodes.id = consignment_sale_products.product_barcode_id").
          #            joins("INNER JOIN product_colors ON product_colors.id = product_barcodes.product_color_id").
          #            joins("INNER JOIN listing_stock_product_details ON listing_stock_product_details.color_id = product_colors.color_id AND listing_stock_product_details.size_id = product_barcodes.size_id").
          #            joins("INNER JOIN listing_stocks ON listing_stocks.id = listing_stock_product_details.listing_stock_id AND listing_stocks.warehouse_id = warehouses.id AND listing_stocks.product_id = product_colors.product_id").
          counter.actived.where(["warehouses.counter_type = ?", params[:counter_type]]).order("common_fields.code ASC").group(:id)
        else
          Warehouse.
            select(:id, :code, :name, :region_id).
            select("common_fields.code AS region_code, common_fields.name AS region_name").
            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{prev_year_date}' THEN consignment_sale_products.total ELSE 0 END) AS prev_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{selected_year_date}' THEN consignment_sale_products.total ELSE 0 END) AS selected_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{prev_year_date}' THEN 1 ELSE 0 END) AS prev_qty_sold").
            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{selected_year_date}' THEN 1 ELSE 0 END) AS selected_qty_sold").
            select("((transaction_detail.bs_quantity + transaction_detail.do_quantity + transaction_detail.rgi_quantity) - (transaction_detail.rw_quantity + transaction_detail.rgo_quantity + transaction_detail.slk_quantity)) AS ending_stock").
            joins(:region).
            joins("INNER JOIN consignment_sales ON consignment_sales.warehouse_id = warehouses.id AND consignment_sales.no_sale <> 't' AND (consignment_sales.transaction_date = '#{prev_year_date}' OR consignment_sales.transaction_date = '#{selected_year_date}')").
            joins("INNER JOIN consignment_sale_products ON consignment_sale_products.consignment_sale_id = consignment_sales.id").
            joins("INNER JOIN product_barcodes ON product_barcodes.id = consignment_sale_products.product_barcode_id").
            joins("INNER JOIN product_colors ON product_colors.id = product_barcodes.product_color_id").
            joins("INNER JOIN listing_stock_product_details ON listing_stock_product_details.color_id = product_colors.color_id AND listing_stock_product_details.size_id = product_barcodes.size_id").
            joins("INNER JOIN listing_stocks ON listing_stocks.id = listing_stock_product_details.listing_stock_id AND listing_stocks.warehouse_id = warehouses.id AND listing_stocks.product_id = product_colors.product_id").
            joins("LEFT JOIN (SELECT listing_stocks.warehouse_id, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'BS' THEN listing_stock_transactions.quantity ELSE 0 END) AS bs_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'DO' THEN listing_stock_transactions.quantity ELSE 0 END) AS do_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'RW' THEN listing_stock_transactions.quantity ELSE 0 END) AS rw_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'RGO' THEN listing_stock_transactions.quantity ELSE 0 END) AS rgo_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'RGI' THEN listing_stock_transactions.quantity ELSE 0 END) AS rgi_quantity, SUM(CASE WHEN listing_stock_transactions.transaction_type = 'SLK' THEN listing_stock_transactions.quantity ELSE 0 END) AS slk_quantity FROM listing_stocks INNER JOIN listing_stock_product_details ON listing_stock_product_details.listing_stock_id = listing_stocks.id INNER JOIN listing_stock_transactions ON listing_stock_transactions.listing_stock_product_detail_id = listing_stock_product_details.id WHERE (listing_stock_transactions.transaction_date <= '#{selected_year_date}') GROUP BY listing_stocks.warehouse_id) AS transaction_detail ON transaction_detail.warehouse_id = warehouses.id").
            counter.actived.where(["warehouses.counter_type = ?", params[:counter_type]]).where(["common_fields.id = ?", params[:region].strip]).order("common_fields.code ASC").group(:id)
        end
        format.js
      else
        format.html
      end
    end
  end
end
