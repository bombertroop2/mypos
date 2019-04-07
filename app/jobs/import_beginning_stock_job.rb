# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class ImportBeginningStockJob < ApplicationJob
  queue_as :default

  def perform(file_path, import_date, current_date_to_string)
    spreadsheet = Roo::Spreadsheet.open(file_path)
    import_date = import_date.to_date
    current_date = current_date_to_string.to_date
    error_message = ""
    error_message = "Import date must be before or equal to today" if import_date > current_date
    beginning_stock_products = []
    if error_message.blank?
      (2..spreadsheet.last_row).each do |i|
        warehouse_code = spreadsheet.row(i)[0].to_s.strip rescue nil
        if warehouse_code.blank?
          error_message = "Error for row (##{i}) : Warehouse code cannot be empty"
          break
        else
          warehouse = Warehouse.select(:id).where(code: warehouse_code).not_in_transit.not_direct_sales.first
          if warehouse.blank?
            error_message = "Error for row (##{i}) : Warehouse #{warehouse_code} doesn't exist"
            break
          else
            warehouse_id = warehouse.id            
          end
        end
        article_code = spreadsheet.row(i)[1].to_s.strip rescue nil
        if article_code.blank?
          error_message = "Error for row (##{i}) : Article code cannot be empty"
          break
        else
          article = Product.select(:id, :size_group_id).where(code: article_code).first
          if article.blank?
            error_message = "Error for row (##{i}) : Article #{article_code} doesn't exist"
            break
          else
            article_id = article.id
          end
        end
        color_code = spreadsheet.row(i)[2].to_s.strip rescue nil
        if color_code.blank?
          error_message = "Error for row (##{i}) : Color code cannot be empty"
          break
        else
          color = Color.joins(:product_colors).select(:id).where(code: color_code, :"product_colors.product_id" => article_id).first
          if color.blank?
            error_message = "Error for row (##{i}) : Color #{color_code} doesn't exist"
            break
          else
            color_id = color.id
          end
        end
        size = spreadsheet.row(i)[3].to_s.strip rescue nil
        if size.blank?
          error_message = "Error for row (##{i}) : Size cannot be empty"
          break
        else
          size_object = Size.joins(:size_group).select(:id).where(size: size, :"size_groups.id" => article.size_group_id).first
          if size_object.blank?
            error_message = "Error for row (##{i}) : Size #{size} doesn't exist"
            break
          else
            size_id = size_object.id
          end          
        end
        if ProductBarcode.select("1 AS one").joins(:product_color).where(size_id: size_id).where(["product_colors.product_id = ? AND product_colors.color_id = ?", article_id, color_id]).blank?
          error_message = "Error for row (##{i}) : Size #{size} or color #{color_code} doesn't exist"
          break
        end
        qty = spreadsheet.row(i)[4].to_s.strip rescue nil
        if qty.blank?
          error_message = "Error for row (##{i}) : Qty cannot be empty"
          break
        elsif qty.to_i < 1
          error_message = "Error for row (##{i}) : Qty must be greater than or equal to 1"
          break
        elsif qty.include?(",") || qty.include?(".")
          error_message = "Error for row (##{i}) : Qty must be integer"
          break
        end
        if error_message.blank?
          beginning_stock_products << BeginningStockProduct.new(product_id: article_id, quantity: qty.to_i, import_date: import_date, warehouse_id: warehouse_id, size_id: size_id, color_id: color_id)
        end
      end
    end
    if error_message.present?
      DuosMailer.import_beginning_stock_error_email(error_message).deliver
    else
      valid = true
      ActiveRecord::Base.transaction do
        beginning_stock_products.each_with_index do |bsp, index|
          begin
            unless valid = bsp.save
              message = bsp.errors.full_messages.map{|error| "#{error}<br/>"}.join
              error_message = "Error(s) for row (##{index + 2}) :<br/>#{message}"
              raise ActiveRecord::Rollback
            end
          rescue ActiveRecord::RecordNotUnique => e
            valid = false
            error_message = "Error for row (##{index + 2}) : The record was already entered."
            raise ActiveRecord::Rollback
          rescue RuntimeError => e
            valid = false
            error_message = "Error for row (##{index + 2}) : #{e.message}"
            raise ActiveRecord::Rollback
          end
        end
      end
      if valid
        DuosMailer.import_beginning_stock_error_email("Beginning stocks were successfully imported").deliver
      else
        DuosMailer.import_beginning_stock_error_email(error_message).deliver
      end
    end
  end
end
