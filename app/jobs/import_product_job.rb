# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class ImportProductJob < ApplicationJob
  queue_as :default

  def perform(file_path, date_to_string)
    spreadsheet = Roo::Spreadsheet.open(file_path)
    current_date = date_to_string.to_date
    products = []
    error_message = ""
    added_spreadsheet_barcodes = []
    barcode = ""
    (3..spreadsheet.last_row).each do |i|
      product_code = spreadsheet.row(i)[0].to_s.strip rescue nil
      if product_code.blank?
        error_message = "Error for row (##{i}) : Article code cannot be empty"
        break
      end
      brand_code = spreadsheet.row(i)[2].to_s.strip rescue nil
      if brand_code.blank?
        error_message = "Error for row (##{i}) : Brand code cannot be empty"
        break
      end
      sex = spreadsheet.row(i)[3].to_s.strip.downcase rescue nil
      if sex.blank?
        error_message = "Error for row (##{i}) : Sex cannot be empty"
        break
      end
      vendor_code = spreadsheet.row(i)[4].to_s.strip rescue nil
      if vendor_code.blank?
        error_message = "Error for row (##{i}) : Vendor code cannot be empty"
        break
      end
      target = spreadsheet.row(i)[5].to_s.strip.downcase rescue nil
      if target.blank?
        error_message = "Error for row (##{i}) : Target cannot be empty"
        break
      end
      model_code = spreadsheet.row(i)[6].to_s.strip rescue nil
      if model_code.blank?
        error_message = "Error for row (##{i}) : Model code cannot be empty"
        break
      end
      goods_type_code = spreadsheet.row(i)[7].to_s.strip rescue nil
      if goods_type_code.blank?
        error_message = "Error for row (##{i}) : Goods type code cannot be empty"
        break
      end
      size_group_code = spreadsheet.row(i)[8].to_s.strip rescue nil
      if size_group_code.blank?
        error_message = "Error for row (##{i}) : Size group code cannot be empty"
        break
      end
      prdct = products.select{|p| p.code.eql?(product_code)}.first
      if prdct.blank?
        brand_id = Brand.where(code: brand_code).pluck(:id).first
        if brand_id.blank?
          error_message = "Error for row (##{i}) : Brand #{brand_code} doesn't exist"
          break
        end
        vendor_id = Vendor.where(code: vendor_code, is_active: true).pluck(:id).first
        if vendor_id.blank?
          error_message = "Error for row (##{i}) : Vendor #{vendor_code} doesn't exist"
          break
        end
        model_id = Model.where(code: model_code).pluck(:id).first
        if model_id.blank?
          error_message = "Error for row (##{i}) : Model #{model_code} doesn't exist"
          break
        end
        goods_type_id = GoodsType.where(code: goods_type_code).pluck(:id).first
        if goods_type_id.blank?
          error_message = "Error for row (##{i}) : Goods type #{goods_type_code} doesn't exist"
          break
        end
        size_group_id = SizeGroup.where(code: size_group_code).pluck(:id).first
        if size_group_id.blank?
          error_message = "Error for row (##{i}) : Size group #{size_group_code} doesn't exist"
          break
        end
        size_id = Size.joins(:size_group).where(size: spreadsheet.row(i)[11].to_s.strip).where(["size_groups.id = ?", size_group_id]).pluck(:id).first
        if size_id.blank?
          error_message = "Error for row (##{i}) : Size #{spreadsheet.row(i)[11].to_s.strip} doesn't exist"
          break
        end
        price_code_id = PriceCode.where(code: spreadsheet.row(i)[12].to_s.strip).pluck(:id).first
        if price_code_id.blank?
          error_message = "Error for row (##{i}) : Price code #{spreadsheet.row(i)[12].to_s.strip} doesn't exist"
          break
        end
        color_id = Color.where(code: spreadsheet.row(i)[14].to_s.strip).pluck(:id).first
        if color_id.blank?
          error_message = "Error for row (##{i}) : Color #{spreadsheet.row(i)[14].to_s.strip} doesn't exist"
          break
        end
        sex = if sex == "null"
          nil
        elsif sex == "ledies"
          "ladies"
        else
          sex
        end
        product = Product.where(code: product_code).first
        if product.blank?
          product = Product.new code: product_code, description: spreadsheet.row(i)[1].to_s, brand_id: brand_id, sex: sex, vendor_id: vendor_id, target: target, model_id: model_id, goods_type_id: goods_type_id, size_group_id: size_group_id, attr_importing_data_via_web: true
        end
        if product.new_record?
          product_detail = product.product_details.build size_id: size_id, price_code_id: price_code_id, size_group_id: size_group_id, attr_importing_data: true, user_is_adding_new_product: true
          product_detail.price_lists.build effective_date: current_date, price: spreadsheet.row(i)[10].to_f, user_is_adding_new_price: true, attr_importing_data: true
          product.cost_lists.build effective_date: current_date, cost: spreadsheet.row(i)[13].to_f, is_user_creating_product: true
        end
        product_color = product.product_colors.build color_id: color_id, attr_importing_data: true
        if added_spreadsheet_barcodes.select{|ab| (ab[:product_code] != product_code || ab[:size_id] != size_id || ab[:color_id] != color_id) && ab[:barcode] == spreadsheet.row(i)[17].to_s.strip}.blank?
          product_color.product_barcodes.build size_id: size_id, barcode: spreadsheet.row(i)[17].to_s.strip
          added_spreadsheet_barcodes << {product_code: product_code, size_id: size_id, color_id: color_id, barcode: spreadsheet.row(i)[17].to_s.strip}
        else
          first_three_digits_company_code = Company.order(:id).pluck(:code).first.first(3)
          if barcode.blank?                        
            prb = ProductBarcode.where(["barcode LIKE ?", "#{first_three_digits_company_code}1S%"]).select(:barcode).order("barcode DESC").first
            barcode = if prb.present?
              "#{first_three_digits_company_code}1S#{prb.barcode.split("#{first_three_digits_company_code}1S")[1].succ}"
            else
              "#{first_three_digits_company_code}1S00001"
            end
          else
            barcode = "#{first_three_digits_company_code}1S#{barcode.split("#{first_three_digits_company_code}1S")[1].succ}"
          end
          product_color.product_barcodes.build size_id: size_id, barcode: barcode
        end
        products << product
      else
        size_id = Size.joins(:size_group).where(size: spreadsheet.row(i)[11].to_s.strip).where(["size_groups.id = ?", prdct.size_group_id]).pluck(:id).first
        if size_id.blank?
          error_message = "Error for row (##{i}) : Size #{spreadsheet.row(i)[11].to_s.strip} doesn't exist"
          break
        end
        price_code_id = PriceCode.where(code: spreadsheet.row(i)[12].to_s.strip).pluck(:id).first
        if price_code_id.blank?
          error_message = "Error for row (##{i}) : Price code #{spreadsheet.row(i)[12].to_s.strip} doesn't exist"
          break
        end
        if prdct.new_record?
          product_detail = prdct.product_details.select{|pd| pd.size_id == size_id && pd.price_code_id == price_code_id}.first
          if product_detail.blank?
            product_detail = prdct.product_details.build size_id: size_id, price_code_id: price_code_id, size_group_id: prdct.size_group_id, attr_importing_data: true, user_is_adding_new_product: true
            product_detail.price_lists.build effective_date: current_date, price: spreadsheet.row(i)[10].to_f, user_is_adding_new_price: true, attr_importing_data: true
          end
        end
        color_id = Color.where(code: spreadsheet.row(i)[14].to_s.strip).pluck(:id).first
        product_color = prdct.product_colors.select{|pc| pc.color_id == color_id}.first
        if product_color.blank?
          product_color = prdct.product_colors.build color_id: color_id, attr_importing_data: true
          if added_spreadsheet_barcodes.select{|ab| (ab[:product_code] != product_code || ab[:size_id] != size_id || ab[:color_id] != color_id) && ab[:barcode] == spreadsheet.row(i)[17].to_s.strip}.blank?
            product_color.product_barcodes.build size_id: size_id, barcode: spreadsheet.row(i)[17].to_s.strip
            added_spreadsheet_barcodes << {product_code: product_code, size_id: size_id, color_id: color_id, barcode: spreadsheet.row(i)[17].to_s.strip}
          else
            first_three_digits_company_code = Company.order(:id).pluck(:code).first.first(3)
            if barcode.blank?                        
              prb = ProductBarcode.where(["barcode LIKE ?", "#{first_three_digits_company_code}1S%"]).select(:barcode).order("barcode DESC").first
              barcode = if prb.present?
                "#{first_three_digits_company_code}1S#{prb.barcode.split("#{first_three_digits_company_code}1S")[1].succ}"
              else
                "#{first_three_digits_company_code}1S00001"
              end
            else
              barcode = "#{first_three_digits_company_code}1S#{barcode.split("#{first_three_digits_company_code}1S")[1].succ}"
            end
            product_color.product_barcodes.build size_id: size_id, barcode: barcode
          end
        else
          product_barcode = product_color.product_barcodes.select{|pb| pb.size_id == size_id}.first
          if product_barcode.blank?
            if added_spreadsheet_barcodes.select{|ab| (ab[:product_code] != product_code || ab[:size_id] != size_id || ab[:color_id] != color_id) && ab[:barcode] == spreadsheet.row(i)[17].to_s.strip}.blank?
              product_color.product_barcodes.build size_id: size_id, barcode: spreadsheet.row(i)[17].to_s.strip
              added_spreadsheet_barcodes << {product_code: product_code, size_id: size_id, color_id: color_id, barcode: spreadsheet.row(i)[17].to_s.strip}
            else
              first_three_digits_company_code = Company.order(:id).pluck(:code).first.first(3)
              if barcode.blank?                        
                prb = ProductBarcode.where(["barcode LIKE ?", "#{first_three_digits_company_code}1S%"]).select(:barcode).order("barcode DESC").first
                barcode = if prb.present?
                  "#{first_three_digits_company_code}1S#{prb.barcode.split("#{first_three_digits_company_code}1S")[1].succ}"
                else
                  "#{first_three_digits_company_code}1S00001"
                end
              else
                barcode = "#{first_three_digits_company_code}1S#{barcode.split("#{first_three_digits_company_code}1S")[1].succ}"
              end
              product_color.product_barcodes.build size_id: size_id, barcode: barcode
            end
          end
        end
      end
    end
    if error_message.present?
      DuosMailer.import_product_error_email(error_message).deliver
    else
      valid = true
      ActiveRecord::Base.transaction do
        products.each do |pr|
          begin
            if Product.select("1 AS one").where(code: pr.code).blank? 
              product_price_codes = []
              pr.product_details.each do |pd|
                product_price_codes << pd.price_code_id
              end
              if valid
                SizeGroup.select(:id).where(id: pr.size_group_id).first.sizes.select(:id).each do |size|
                  product_price_codes.uniq.each do |ppc|
                    if pr.product_details.select{|pd| pd.price_code_id == ppc && pd.size_id == size.id}.blank?
                      existed_product_detail = pr.product_details.select{|pd| pd.price_code_id == ppc}.first
                      other_size_price = existed_product_detail.price_lists.last.price
                      product_detail = pr.product_details.build size_id: size.id, price_code_id: ppc, size_group_id: pr.size_group_id, attr_importing_data: true, user_is_adding_new_product: true
                      product_detail.price_lists.build effective_date: current_date, price: other_size_price, user_is_adding_new_price: true, attr_importing_data: true
                    end
                  end
                  pr.product_colors.each do |pc|
                    if pc.product_barcodes.select{|pb| pb.size_id == size.id}.blank?
                      first_three_digits_company_code = Company.order(:id).pluck(:code).first.first(3)
                      if barcode.blank?                        
                        prb = ProductBarcode.where(["barcode LIKE ?", "#{first_three_digits_company_code}1S%"]).select(:barcode).order("barcode DESC").first
                        barcode = if prb.present?
                          "#{first_three_digits_company_code}1S#{prb.barcode.split("#{first_three_digits_company_code}1S")[1].succ}"
                        else
                          "#{first_three_digits_company_code}1S00001"
                        end
                      else
                        barcode = "#{first_three_digits_company_code}1S#{barcode.split("#{first_three_digits_company_code}1S")[1].succ}"
                      end
                      pc.product_barcodes.build size_id: size.id, barcode: barcode
                    end
                  end
                end
                unless valid = pr.save
                  message = pr.errors.full_messages.map{|error| "#{error}<br/>"}.join
                  error_message = message
                  raise ActiveRecord::Rollback
                end
              else
                raise ActiveRecord::Rollback
              end
            else
              if valid
                SizeGroup.select(:id).where(id: pr.size_group_id).first.sizes.select(:id).each do |size|
                  pr.product_colors.each do |pc|
                    if ProductColor.select("1 AS one").where(product_id: pr.id, color_id: pc.color_id).blank?
                      if pc.new_record?
                        if pc.product_barcodes.select{|pb| pb.size_id == size.id}.blank?
                          first_three_digits_company_code = Company.order(:id).pluck(:code).first.first(3)
                          if barcode.blank?                        
                            prb = ProductBarcode.where(["barcode LIKE ?", "#{first_three_digits_company_code}1S%"]).select(:barcode).order("barcode DESC").first
                            barcode = if prb.present?
                              "#{first_three_digits_company_code}1S#{prb.barcode.split("#{first_three_digits_company_code}1S")[1].succ}"
                            else
                              "#{first_three_digits_company_code}1S00001"
                            end
                          else
                            barcode = "#{first_three_digits_company_code}1S#{barcode.split("#{first_three_digits_company_code}1S")[1].succ}"
                          end
                          pc.product_barcodes.build size_id: size.id, barcode: barcode
                        end
                        unless valid = pc.save
                          message = pc.errors.full_messages.map{|error| "#{error}<br/>"}.join
                          error_message = message
                          raise ActiveRecord::Rollback
                        end
                      end
                    end
                  end
                end
              else
                raise ActiveRecord::Rollback
              end
            end
          rescue ActiveRecord::RecordNotUnique => e
            valid = false
            error_message = "Article code #{pr.code} has already been taken"
            raise ActiveRecord::Rollback
          rescue RuntimeError => e
            valid = false
            error_message = e.message
            raise ActiveRecord::Rollback
          end
        end
      end
      if valid
        DuosMailer.import_product_error_email("Articles were successfully imported").deliver
      else
        DuosMailer.import_product_error_email(error_message).deliver
      end
    end
  end
end
