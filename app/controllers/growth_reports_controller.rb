class GrowthReportsController < ApplicationController
  def index
    respond_to do |format|
      if params[:region].present?
        @warehouses = if params[:region].strip.eql?("0")
          Warehouse.
            select(:id, :code, :name, :region_id).
            select("common_fields.code AS region_code, common_fields.name AS region_name").
            joins(:region).
            counter.actived.where(["warehouses.counter_type = ?", params[:counter_type]]).order("common_fields.code ASC").group(:id)
        else
          Warehouse.
            select(:id, :code, :name, :region_id).
            select("common_fields.code AS region_code, common_fields.name AS region_name").
            joins(:region).
            counter.actived.where(["warehouses.counter_type = ?", params[:counter_type]]).where(["common_fields.id = ?", params[:region].strip]).order("common_fields.code ASC").group(:id)
        end
        format.js
      else
        format.html
      end
    end
  end
end
