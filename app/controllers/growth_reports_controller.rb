class GrowthReportsController < ApplicationController
  def index
    respond_to do |format|
      if params[:region].present?
        if params[:date].present?
          prev_year_date = params[:date].to_date - 1.year
          selected_year_date = params[:date].to_date
          if params[:region].strip.eql?("0")
            @warehouses = Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              joins(:region).
              where(["warehouses.counter_type = ?", params[:counter_type]]).
              order("common_fields.code ASC").
              group(:id, "common_fields.code", "common_fields.name")
          else
            @warehouses = Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              joins(:region).
              where(["warehouses.counter_type = ?", params[:counter_type]]).
              where(["common_fields.id = ?", params[:region].strip]).
              order("common_fields.code ASC").
              group(:id, "common_fields.code", "common_fields.name")
          end
          @prev_consignment_sales = ConsignmentSale.
            select(:warehouse_id).
            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{prev_year_date}' THEN consignment_sale_products.total ELSE 0 END) AS prev_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{prev_year_date}' THEN 1 ELSE 0 END) AS prev_qty_sold").
            joins(:consignment_sale_products).
            where(warehouse_id: @warehouses.map(&:id)).
            where(["consignment_sales.transaction_date = ?", prev_year_date]).
            group(:warehouse_id)
          @consignment_sales = ConsignmentSale.
            select(:warehouse_id).
            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{selected_year_date}' THEN consignment_sale_products.total ELSE 0 END) AS selected_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{selected_year_date}' THEN 1 ELSE 0 END) AS selected_qty_sold").
            joins(:consignment_sale_products).
            where(warehouse_id: @warehouses.map(&:id)).
            where(["consignment_sales.transaction_date = ?", selected_year_date]).
            group(:warehouse_id)
        elsif params[:month].present?
          prev_year_beginning_of_month = "1/#{params[:month]}/#{params[:year].to_i - 1}".to_date
          prev_year_end_of_month = prev_year_beginning_of_month.end_of_month
          selected_year_beginning_of_month = "1/#{params[:month]}/#{params[:year]}".to_date
          selected_year_end_of_month = selected_year_beginning_of_month.end_of_month
          if params[:region].strip.eql?("0")
            @warehouses = Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              joins(:region).
              where(["warehouses.counter_type = ?", params[:counter_type]]).
              order("common_fields.code ASC").
              group(:id, "common_fields.code", "common_fields.name")
          else
            @warehouses = Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              joins(:region).
              where(["warehouses.counter_type = ?", params[:counter_type]]).
              where(["common_fields.id = ?", params[:region].strip]).
              order("common_fields.code ASC").
              group(:id, "common_fields.code", "common_fields.name")
          end
          @prev_consignment_sales = ConsignmentSale.
            select(:warehouse_id).
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_month}' THEN consignment_sale_products.total ELSE 0 END) AS prev_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_month}' THEN 1 ELSE 0 END) AS prev_qty_sold").
            joins(:consignment_sale_products).
            where(warehouse_id: @warehouses.map(&:id), transaction_date: prev_year_beginning_of_month..prev_year_end_of_month).
            group(:warehouse_id)
          @consignment_sales = ConsignmentSale.
            select(:warehouse_id).
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_month}' THEN consignment_sale_products.total ELSE 0 END) AS selected_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_month}' THEN 1 ELSE 0 END) AS selected_qty_sold").
            joins(:consignment_sale_products).
            where(warehouse_id: @warehouses.map(&:id), transaction_date: selected_year_beginning_of_month..selected_year_end_of_month).
            group(:warehouse_id)
        elsif params[:date_range].present?
          splitted_date_range = params[:date_range].split("-")
          @prev_date_beginning = splitted_date_range[0].strip.to_date - 1.year
          @prev_date_end = splitted_date_range[1].strip.to_date - 1.year
          @selected_date_beginning = splitted_date_range[0].strip.to_date
          @selected_date_end = splitted_date_range[1].strip.to_date
          if params[:region].strip.eql?("0")
            @warehouses = Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              joins(:region).
              where(["warehouses.counter_type = ?", params[:counter_type]]).
              order("common_fields.code ASC").
              group(:id, "common_fields.code", "common_fields.name")
          else
            @warehouses = Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              joins(:region).
              where(["warehouses.counter_type = ?", params[:counter_type]]).
              where(["common_fields.id = ?", params[:region].strip]).
              order("common_fields.code ASC").
              group(:id, "common_fields.code", "common_fields.name")
          end
          @prev_consignment_sales = ConsignmentSale.
            select(:warehouse_id).
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{@prev_date_beginning}' AND consignment_sales.transaction_date <= '#{@prev_date_end}' THEN consignment_sale_products.total ELSE 0 END) AS prev_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{@prev_date_beginning}' AND consignment_sales.transaction_date <= '#{@prev_date_end}' THEN 1 ELSE 0 END) AS prev_qty_sold").
            joins(:consignment_sale_products).
            where(warehouse_id: @warehouses.map(&:id), transaction_date: @prev_date_beginning..@prev_date_end).
            group(:warehouse_id)
          @consignment_sales = ConsignmentSale.
            select(:warehouse_id).
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{@selected_date_beginning}' AND consignment_sales.transaction_date <= '#{@selected_date_end}' THEN consignment_sale_products.total ELSE 0 END) AS selected_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{@selected_date_beginning}' AND consignment_sales.transaction_date <= '#{@selected_date_end}' THEN 1 ELSE 0 END) AS selected_qty_sold").
            joins(:consignment_sale_products).
            where(warehouse_id: @warehouses.map(&:id), transaction_date: @selected_date_beginning..@selected_date_end).
            group(:warehouse_id)
        else
          prev_year_beginning_of_year = "1/1/#{params[:year].to_i - 1}".to_date
          prev_year_end_of_year = prev_year_beginning_of_year.end_of_year
          selected_year_beginning_of_year = "1/1/#{params[:year]}".to_date
          selected_year_end_of_year = selected_year_beginning_of_year.end_of_year
          if params[:region].strip.eql?("0")
            @warehouses = Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              joins(:region).
              where(["warehouses.counter_type = ?", params[:counter_type]]).
              order("common_fields.code ASC").
              group(:id, "common_fields.code", "common_fields.name")
          else
            @warehouses = Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              joins(:region).
              where(["warehouses.counter_type = ?", params[:counter_type]]).
              where(["common_fields.id = ?", params[:region].strip]).
              order("common_fields.code ASC").
              group(:id, "common_fields.code", "common_fields.name")
          end
          @prev_consignment_sales = ConsignmentSale.
            select(:warehouse_id).
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_year}' THEN consignment_sale_products.total ELSE 0 END) AS prev_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_year}' THEN 1 ELSE 0 END) AS prev_qty_sold").
            joins(:consignment_sale_products).
            where(warehouse_id: @warehouses.map(&:id), transaction_date: prev_year_beginning_of_year..prev_year_end_of_year).
            group(:warehouse_id)
          @consignment_sales = ConsignmentSale.
            select(:warehouse_id).
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_year}' THEN consignment_sale_products.total ELSE 0 END) AS selected_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_year}' THEN 1 ELSE 0 END) AS selected_qty_sold").
            joins(:consignment_sale_products).
            where(warehouse_id: @warehouses.map(&:id), transaction_date: selected_year_beginning_of_year..selected_year_end_of_year).
            group(:warehouse_id)
        end
        format.js
      else
        format.html
      end
    end
  end

  def print
    respond_to do |format|
      if params[:region].present?
        if params[:date].present?
          prev_year_date = params[:date].to_date - 1.year
          selected_year_date = params[:date].to_date
          if params[:region].strip.eql?("0")
            @warehouses = Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              joins(:region).
              where(["warehouses.counter_type = ?", params[:counter_type]]).
              order("common_fields.code ASC").
              group(:id, "common_fields.code", "common_fields.name")
          else
            @warehouses = Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              joins(:region).
              where(["warehouses.counter_type = ?", params[:counter_type]]).
              where(["common_fields.id = ?", params[:region].strip]).
              order("common_fields.code ASC").
              group(:id, "common_fields.code", "common_fields.name")
          end
          @prev_consignment_sales = ConsignmentSale.
            select(:warehouse_id).
            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{prev_year_date}' THEN consignment_sale_products.total ELSE 0 END) AS prev_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{prev_year_date}' THEN 1 ELSE 0 END) AS prev_qty_sold").
            joins(:consignment_sale_products).
            where(warehouse_id: @warehouses.map(&:id)).
            where(["consignment_sales.transaction_date = ?", prev_year_date]).
            group(:warehouse_id)
          @consignment_sales = ConsignmentSale.
            select(:warehouse_id).
            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{selected_year_date}' THEN consignment_sale_products.total ELSE 0 END) AS selected_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date = '#{selected_year_date}' THEN 1 ELSE 0 END) AS selected_qty_sold").
            joins(:consignment_sale_products).
            where(warehouse_id: @warehouses.map(&:id)).
            where(["consignment_sales.transaction_date = ?", selected_year_date]).
            group(:warehouse_id)
        elsif params[:month].present?
          prev_year_beginning_of_month = "1/#{params[:month]}/#{params[:year].to_i - 1}".to_date
          prev_year_end_of_month = prev_year_beginning_of_month.end_of_month
          selected_year_beginning_of_month = "1/#{params[:month]}/#{params[:year]}".to_date
          selected_year_end_of_month = selected_year_beginning_of_month.end_of_month
          if params[:region].strip.eql?("0")
            @warehouses = Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              joins(:region).
              where(["warehouses.counter_type = ?", params[:counter_type]]).
              order("common_fields.code ASC").
              group(:id, "common_fields.code", "common_fields.name")
          else
            @warehouses = Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              joins(:region).
              where(["warehouses.counter_type = ?", params[:counter_type]]).
              where(["common_fields.id = ?", params[:region].strip]).
              order("common_fields.code ASC").
              group(:id, "common_fields.code", "common_fields.name")
          end
          @prev_consignment_sales = ConsignmentSale.
            select(:warehouse_id).
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_month}' THEN consignment_sale_products.total ELSE 0 END) AS prev_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_month}' THEN 1 ELSE 0 END) AS prev_qty_sold").
            joins(:consignment_sale_products).
            where(warehouse_id: @warehouses.map(&:id), transaction_date: prev_year_beginning_of_month..prev_year_end_of_month).
            group(:warehouse_id)
          @consignment_sales = ConsignmentSale.
            select(:warehouse_id).
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_month}' THEN consignment_sale_products.total ELSE 0 END) AS selected_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_month}' THEN 1 ELSE 0 END) AS selected_qty_sold").
            joins(:consignment_sale_products).
            where(warehouse_id: @warehouses.map(&:id), transaction_date: selected_year_beginning_of_month..selected_year_end_of_month).
            group(:warehouse_id)
        elsif params[:date_range].present?
          splitted_date_range = params[:date_range].split("-")
          @prev_date_beginning = splitted_date_range[0].strip.to_date - 1.year
          @prev_date_end = splitted_date_range[1].strip.to_date - 1.year
          @selected_date_beginning = splitted_date_range[0].strip.to_date
          @selected_date_end = splitted_date_range[1].strip.to_date
          if params[:region].strip.eql?("0")
            @warehouses = Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              joins(:region).
              where(["warehouses.counter_type = ?", params[:counter_type]]).
              order("common_fields.code ASC").
              group(:id, "common_fields.code", "common_fields.name")
          else
            @warehouses = Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              joins(:region).
              where(["warehouses.counter_type = ?", params[:counter_type]]).
              where(["common_fields.id = ?", params[:region].strip]).
              order("common_fields.code ASC").
              group(:id, "common_fields.code", "common_fields.name")
          end
          @prev_consignment_sales = ConsignmentSale.
            select(:warehouse_id).
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{@prev_date_beginning}' AND consignment_sales.transaction_date <= '#{@prev_date_end}' THEN consignment_sale_products.total ELSE 0 END) AS prev_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{@prev_date_beginning}' AND consignment_sales.transaction_date <= '#{@prev_date_end}' THEN 1 ELSE 0 END) AS prev_qty_sold").
            joins(:consignment_sale_products).
            where(warehouse_id: @warehouses.map(&:id), transaction_date: @prev_date_beginning..@prev_date_end).
            group(:warehouse_id)
          @consignment_sales = ConsignmentSale.
            select(:warehouse_id).
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{@selected_date_beginning}' AND consignment_sales.transaction_date <= '#{@selected_date_end}' THEN consignment_sale_products.total ELSE 0 END) AS selected_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{@selected_date_beginning}' AND consignment_sales.transaction_date <= '#{@selected_date_end}' THEN 1 ELSE 0 END) AS selected_qty_sold").
            joins(:consignment_sale_products).
            where(warehouse_id: @warehouses.map(&:id), transaction_date: @selected_date_beginning..@selected_date_end).
            group(:warehouse_id)
        else
          prev_year_beginning_of_year = "1/1/#{params[:year].to_i - 1}".to_date
          prev_year_end_of_year = prev_year_beginning_of_year.end_of_year
          selected_year_beginning_of_year = "1/1/#{params[:year]}".to_date
          selected_year_end_of_year = selected_year_beginning_of_year.end_of_year
          if params[:region].strip.eql?("0")
            @warehouses = Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              joins(:region).
              where(["warehouses.counter_type = ?", params[:counter_type]]).
              order("common_fields.code ASC").
              group(:id, "common_fields.code", "common_fields.name")
          else
            @warehouses = Warehouse.
              select(:id, :code, :name, :region_id).
              select("common_fields.code AS region_code, common_fields.name AS region_name").
              joins(:region).
              where(["warehouses.counter_type = ?", params[:counter_type]]).
              where(["common_fields.id = ?", params[:region].strip]).
              order("common_fields.code ASC").
              group(:id, "common_fields.code", "common_fields.name")
          end
          @prev_consignment_sales = ConsignmentSale.
            select(:warehouse_id).
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_year}' THEN consignment_sale_products.total ELSE 0 END) AS prev_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_year}' THEN 1 ELSE 0 END) AS prev_qty_sold").
            joins(:consignment_sale_products).
            where(warehouse_id: @warehouses.map(&:id), transaction_date: prev_year_beginning_of_year..prev_year_end_of_year).
            group(:warehouse_id)
          @consignment_sales = ConsignmentSale.
            select(:warehouse_id).
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_year}' THEN consignment_sale_products.total ELSE 0 END) AS selected_net_sales").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_year}' THEN 1 ELSE 0 END) AS selected_qty_sold").
            joins(:consignment_sale_products).
            where(warehouse_id: @warehouses.map(&:id), transaction_date: selected_year_beginning_of_year..selected_year_end_of_year).
            group(:warehouse_id)
        end
        format.js
      else
        format.html
      end
    end
  end
  
  def export
    respond_to do |format|
      file_name = ""
      if params[:date].present?
        file_name = "daily_growth_report"
        prev_year_date = params[:date].to_date - 1.year
        selected_year_date = params[:date].to_date
        if params[:region].strip.eql?("0")
          @warehouses = Warehouse.
            select(:id, :code, :name, :region_id).
            select("common_fields.code AS region_code, common_fields.name AS region_name").
            joins(:region).
            where(["warehouses.counter_type = ?", params[:counter_type]]).
            order("common_fields.code ASC").
            group(:id, "common_fields.code", "common_fields.name")
        else
          @warehouses = Warehouse.
            select(:id, :code, :name, :region_id).
            select("common_fields.code AS region_code, common_fields.name AS region_name").
            joins(:region).
            where(["warehouses.counter_type = ?", params[:counter_type]]).
            where(["common_fields.id = ?", params[:region].strip]).
            order("common_fields.code ASC").
            group(:id, "common_fields.code", "common_fields.name")
        end
        @prev_consignment_sales = ConsignmentSale.
          select(:warehouse_id).
          select("SUM(CASE WHEN consignment_sales.transaction_date = '#{prev_year_date}' THEN consignment_sale_products.total ELSE 0 END) AS prev_net_sales").
          select("SUM(CASE WHEN consignment_sales.transaction_date = '#{prev_year_date}' THEN 1 ELSE 0 END) AS prev_qty_sold").
          joins(:consignment_sale_products).
          where(warehouse_id: @warehouses.map(&:id)).
          where(["consignment_sales.transaction_date = ?", prev_year_date]).
          group(:warehouse_id)
        @consignment_sales = ConsignmentSale.
          select(:warehouse_id).
          select("SUM(CASE WHEN consignment_sales.transaction_date = '#{selected_year_date}' THEN consignment_sale_products.total ELSE 0 END) AS selected_net_sales").
          select("SUM(CASE WHEN consignment_sales.transaction_date = '#{selected_year_date}' THEN 1 ELSE 0 END) AS selected_qty_sold").
          joins(:consignment_sale_products).
          where(warehouse_id: @warehouses.map(&:id)).
          where(["consignment_sales.transaction_date = ?", selected_year_date]).
          group(:warehouse_id)
      elsif params[:month].present?
        file_name = "mtd_growth_report"
        prev_year_beginning_of_month = "1/#{params[:month]}/#{params[:year].to_i - 1}".to_date
        prev_year_end_of_month = prev_year_beginning_of_month.end_of_month
        selected_year_beginning_of_month = "1/#{params[:month]}/#{params[:year]}".to_date
        selected_year_end_of_month = selected_year_beginning_of_month.end_of_month
        if params[:region].strip.eql?("0")
          @warehouses = Warehouse.
            select(:id, :code, :name, :region_id).
            select("common_fields.code AS region_code, common_fields.name AS region_name").
            joins(:region).
            where(["warehouses.counter_type = ?", params[:counter_type]]).
            order("common_fields.code ASC").
            group(:id, "common_fields.code", "common_fields.name")
        else
          @warehouses = Warehouse.
            select(:id, :code, :name, :region_id).
            select("common_fields.code AS region_code, common_fields.name AS region_name").
            joins(:region).
            where(["warehouses.counter_type = ?", params[:counter_type]]).
            where(["common_fields.id = ?", params[:region].strip]).
            order("common_fields.code ASC").
            group(:id, "common_fields.code", "common_fields.name")
        end
        @prev_consignment_sales = ConsignmentSale.
          select(:warehouse_id).
          select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_month}' THEN consignment_sale_products.total ELSE 0 END) AS prev_net_sales").
          select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_month}' THEN 1 ELSE 0 END) AS prev_qty_sold").
          joins(:consignment_sale_products).
          where(warehouse_id: @warehouses.map(&:id), transaction_date: prev_year_beginning_of_month..prev_year_end_of_month).
          group(:warehouse_id)
        @consignment_sales = ConsignmentSale.
          select(:warehouse_id).
          select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_month}' THEN consignment_sale_products.total ELSE 0 END) AS selected_net_sales").
          select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_month}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_month}' THEN 1 ELSE 0 END) AS selected_qty_sold").
          joins(:consignment_sale_products).
          where(warehouse_id: @warehouses.map(&:id), transaction_date: selected_year_beginning_of_month..selected_year_end_of_month).
          group(:warehouse_id)
      elsif params[:date_range].present?
        file_name = "custom_range_growth_report"
        splitted_date_range = params[:date_range].split("-")
        @prev_date_beginning = splitted_date_range[0].strip.to_date - 1.year
        @prev_date_end = splitted_date_range[1].strip.to_date - 1.year
        @selected_date_beginning = splitted_date_range[0].strip.to_date
        @selected_date_end = splitted_date_range[1].strip.to_date
        if params[:region].strip.eql?("0")
          @warehouses = Warehouse.
            select(:id, :code, :name, :region_id).
            select("common_fields.code AS region_code, common_fields.name AS region_name").
            joins(:region).
            where(["warehouses.counter_type = ?", params[:counter_type]]).
            order("common_fields.code ASC").
            group(:id, "common_fields.code", "common_fields.name")
        else
          @warehouses = Warehouse.
            select(:id, :code, :name, :region_id).
            select("common_fields.code AS region_code, common_fields.name AS region_name").
            joins(:region).
            where(["warehouses.counter_type = ?", params[:counter_type]]).
            where(["common_fields.id = ?", params[:region].strip]).
            order("common_fields.code ASC").
            group(:id, "common_fields.code", "common_fields.name")
        end
        @prev_consignment_sales = ConsignmentSale.
          select(:warehouse_id).
          select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{@prev_date_beginning}' AND consignment_sales.transaction_date <= '#{@prev_date_end}' THEN consignment_sale_products.total ELSE 0 END) AS prev_net_sales").
          select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{@prev_date_beginning}' AND consignment_sales.transaction_date <= '#{@prev_date_end}' THEN 1 ELSE 0 END) AS prev_qty_sold").
          joins(:consignment_sale_products).
          where(warehouse_id: @warehouses.map(&:id), transaction_date: @prev_date_beginning..@prev_date_end).
          group(:warehouse_id)
        @consignment_sales = ConsignmentSale.
          select(:warehouse_id).
          select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{@selected_date_beginning}' AND consignment_sales.transaction_date <= '#{@selected_date_end}' THEN consignment_sale_products.total ELSE 0 END) AS selected_net_sales").
          select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{@selected_date_beginning}' AND consignment_sales.transaction_date <= '#{@selected_date_end}' THEN 1 ELSE 0 END) AS selected_qty_sold").
          joins(:consignment_sale_products).
          where(warehouse_id: @warehouses.map(&:id), transaction_date: @selected_date_beginning..@selected_date_end).
          group(:warehouse_id)
      else
        file_name = "ytd_growth_report"
        prev_year_beginning_of_year = "1/1/#{params[:year].to_i - 1}".to_date
        prev_year_end_of_year = prev_year_beginning_of_year.end_of_year
        selected_year_beginning_of_year = "1/1/#{params[:year]}".to_date
        selected_year_end_of_year = selected_year_beginning_of_year.end_of_year
        if params[:region].strip.eql?("0")
          @warehouses = Warehouse.
            select(:id, :code, :name, :region_id).
            select("common_fields.code AS region_code, common_fields.name AS region_name").
            joins(:region).
            where(["warehouses.counter_type = ?", params[:counter_type]]).
            order("common_fields.code ASC").
            group(:id, "common_fields.code", "common_fields.name")
        else
          @warehouses = Warehouse.
            select(:id, :code, :name, :region_id).
            select("common_fields.code AS region_code, common_fields.name AS region_name").
            joins(:region).
            where(["warehouses.counter_type = ?", params[:counter_type]]).
            where(["common_fields.id = ?", params[:region].strip]).
            order("common_fields.code ASC").
            group(:id, "common_fields.code", "common_fields.name")
        end
        @prev_consignment_sales = ConsignmentSale.
          select(:warehouse_id).
          select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_year}' THEN consignment_sale_products.total ELSE 0 END) AS prev_net_sales").
          select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{prev_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{prev_year_end_of_year}' THEN 1 ELSE 0 END) AS prev_qty_sold").
          joins(:consignment_sale_products).
          where(warehouse_id: @warehouses.map(&:id), transaction_date: prev_year_beginning_of_year..prev_year_end_of_year).
          group(:warehouse_id)
        @consignment_sales = ConsignmentSale.
          select(:warehouse_id).
          select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_year}' THEN consignment_sale_products.total ELSE 0 END) AS selected_net_sales").
          select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{selected_year_beginning_of_year}' AND consignment_sales.transaction_date <= '#{selected_year_end_of_year}' THEN 1 ELSE 0 END) AS selected_qty_sold").
          joins(:consignment_sale_products).
          where(warehouse_id: @warehouses.map(&:id), transaction_date: selected_year_beginning_of_year..selected_year_end_of_year).
          group(:warehouse_id)
      end
      format.pdf do
        render pdf: file_name,
          template: "growth_reports/export.html.erb",
          orientation: 'Landscape',
          layout: 'pdf.html',
          disposition: 'attachment'
      end
    end
  end  
end
