class ImportDataJob < ApplicationJob
  queue_as :default

  def perform(type, filename, step=1)
    if type.eql?("product")
      start_from = step * 9999 - 9999 + 2 + step - 1
      end_at = step * 9999 + 2 + step - 1
      error = false
      error_messages = []
      products = []
      added_product_codes = []
      workbook = Creek::Book.new Rails.root.join("public", filename).to_s
      worksheets = workbook.sheets

      worksheets.each do |worksheet|
        worksheet.rows.each_with_index do |row, idx|          
          next if idx < start_from
          break if idx > end_at
          if row.present? && Product.select("1 AS one").where(code: row["A#{idx + 1}"].strip).blank? && !added_product_codes.include?(row["A#{idx + 1}"].strip)
            puts "index => #{idx}"
            brand_id = 0
            sex = ""
            target = ""
            model_id = 0
            goods_type_id = 0
            size_group_id = 0
            begin          
              goods_type_code = row["G#{idx + 1}"].strip == "N/A" ? "NA" : row["G#{idx + 1}"].strip
              target_value = if row["E#{idx + 1}"] == nil || row["E#{idx + 1}"].strip == ""
                "normal"
              else
                row["E#{idx + 1}"].strip.downcase
              end
              brand_id = Brand.select(:id).where(code: row["B#{idx + 1}"].strip).first.id
              sex = Product::SEX.select{ |x| x[1] == (row["C#{idx + 1}"].strip.eql?("B") || row["C#{idx + 1}"].strip.eql?("BAGS") ? "ladies" : (row["C#{idx + 1}"].strip.eql?("MENS") ? "man" : row["C#{idx + 1}"].strip.downcase)) }.first.first.downcase
              vendor_id = Vendor.select(:id).where(code: row["D#{idx + 1}"].strip).first.id
              target = Product::TARGETS.select{ |x| x[1] == target_value }.first.first.downcase
              model_id = Model.select(:id).where(code: row["F#{idx + 1}"].strip).first.id
              goods_type_id = GoodsType.select(:id).where(code: goods_type_code).first.id
              size_group_id = SizeGroup.select(:id).where(code: row["H#{idx + 1}"].strip).first.id
              product = Product.new code: row["A#{idx + 1}"].strip, brand_id: brand_id, sex: sex, vendor_id: vendor_id, target: target, model_id: model_id, goods_type_id: goods_type_id, size_group_id: size_group_id, additional_information: (row["I#{idx + 1}"].present? ? row["I#{idx + 1}"].strip : nil), attr_importing_data: true
              unless product.valid?
                error_messages << product.errors.inspect
                error_messages << "invalid index => #{idx}"
                error = true
              else
                products << product
                added_product_codes << row["A#{idx + 1}"].strip
              end
            rescue Exception => e
              error_messages << e.inspect
              error_messages << "invalid index => #{idx}, brand id => #{brand_id}, sex => #{sex}, vendor_id => #{vendor_id}, target => #{target}, model_id => #{model_id}, goods_type_id => #{goods_type_id}, size_group_id => #{size_group_id}"
              error = true
            end
          end
        end
      end
      if error
        error_messages.each_with_index do |error_message, idx|
          puts "#{idx+1}. #{error_message}"
        end
      else
        begin
          Product.import(products)          
        rescue Exception => e
          puts "error => #{e.inspect}"
        end
      end
    elsif type.eql?("product detail")
      start_from = step * 9999 - 9999 + 2 + step - 1
      end_at = step * 9999 + 2 + step - 1
      error = false
      error_messages = []
      product_details = []
      workbook = Creek::Book.new Rails.root.join("public", filename).to_s
      worksheets = workbook.sheets

      worksheets.each do |worksheet|
        worksheet.rows.each_with_index do |row, idx|          
          next if idx < start_from
          break if idx > end_at
          if row.present?
            puts "index => #{idx}"
            size_id = 0
            product_id = 0
            price_code_id = 0
            product = Product.select(:id, :size_group_id).where(code: row["B#{idx + 1}"].strip).first
            if product.present?
              begin          
                size_group_id = product.size_group_id
                size_id = Size.select(:id).where(size: row["A#{idx + 1}"], size_group_id: size_group_id).first.id
                product_id = product.id
                price_code_id = PriceCode.select(:id).where(code: row["C#{idx + 1}"].strip).first.id
                product_detail = ProductDetail.new size_id: size_id, product_id: product_id, price_code_id: price_code_id, size_group_id: size_group_id, user_is_adding_new_product: true, attr_importing_data: true
                unless product_detail.valid?
                  error_messages << product_detail.errors.inspect
                  error_messages << "invalid index => #{idx}"
                  error = true
                else
                  product_details << product_detail
                end
              rescue Exception => e
                error_messages << e.inspect
                error_messages << "invalid index => #{idx}, size id => #{size_id}, product_id => #{product_id}, size_group_id => #{size_group_id}, price_code_id => #{price_code_id}"
                error = true
              end
            end
          end
        end
      end
      if error
        error_messages.each_with_index do |error_message, idx|
          puts "#{idx+1}. #{error_message}"
        end
      else
        begin
          ProductDetail.import(product_details)          
        rescue Exception => e
          puts "error => #{e.inspect}"
        end
      end
    elsif type.eql?("product costs")
      start_from = step * 9999 - 9999 + 2 + step - 1
      end_at = step * 9999 + 2 + step - 1
      error = false
      error_messages = []
      cost_lists = []
      added_cost_lists = []
      workbook = Creek::Book.new Rails.root.join("public", filename).to_s
      worksheets = workbook.sheets

      worksheets.each do |worksheet|
        worksheet.rows.each_with_index do |row, idx|  
          next if idx < start_from
          break if idx > end_at
          if row.present?
            puts "index => #{idx}"
            product = Product.select(:id).where(code: row["A#{idx + 1}"].strip).first
            if product.present? && added_cost_lists.select{|added_cost_list| added_cost_list.effective_date == row["B#{idx + 1}"] && added_cost_list.product_id == product.id}.blank?
              begin
                product_id = product.id
                cost_list = CostList.new effective_date: row["B#{idx + 1}"], cost: row["C#{idx + 1}"], product_id: product_id, attr_importing_data: true
                unless cost_list.valid?
                  error_messages << cost_list.errors.inspect
                  error_messages << "invalid index => #{idx}"
                  error = true
                else
                  cost_lists << cost_list
                  added_cost_lists << cost_list
                end
              rescue Exception => e
                error_messages << e.inspect
                error_messages << "invalid index => #{idx}, product_id => #{product_id}"
                error = true
              end
            end
          end
        end
      end
      if error
        error_messages.each_with_index do |error_message, idx|
          puts "#{idx+1}. #{error_message}"
        end
      else
        begin
          CostList.import(cost_lists)
        rescue Exception => e
          puts "error => #{e.inspect}"
        end
      end
    elsif type.eql?("product prices")
      # import per 100000 row
      start_from = step * 99999 - 99999 + 2 + step - 1
      end_at = step * 99999 + 2 + step - 1
      error = false
      error_messages = []
      price_lists = []
      new_cost_lists = []
      added_new_cost_lists = []
      workbook = Creek::Book.new Rails.root.join("public", filename).to_s
      worksheets = workbook.sheets

      worksheets.each do |worksheet|
        worksheet.rows.each_with_index do |row, idx|  
          next if idx < start_from
          break if idx > end_at
          if row.present?
            puts "index => #{idx}"
            product_detail_id = 0
            product_id = 0
            cost = 0
            product_detail = ProductDetail.select(:id, :product_id).joins(:size, :product, :price_code).where(["sizes.size_group_id = products.size_group_id AND sizes.size = ? AND products.code = ? AND common_fields.code = ?", row["A#{idx + 1}"].strip, row["B#{idx + 1}"].strip, row["C#{idx + 1}"].strip]).first
            begin
              product_detail_id = product_detail.id
              product_id = product_detail.product_id
              price = row["E#{idx + 1}"] <= 0 ? 1 : row["E#{idx + 1}"]
              effective_date = row["D#{idx + 1}"].strftime("%d/%m/%Y").to_date
              cost_list = CostList.select(:cost).where(["effective_date = ? AND product_id = ?", effective_date, product_id]).first
              new_cost_list = nil
              cost = if cost_list.present?
                cost_list.cost
              else
                cls = CostList.where(product_id: product_id).select(:id, :cost, :effective_date)
                cls.each do |cl|
                  if effective_date >= cl.effective_date
                    new_cost_list = CostList.new(effective_date: effective_date, cost: cl.cost, product_id: product_id, attr_importing_data: true)
                    break
                  end
                end
                new_cost_list.cost
              end
              price_list = PriceList.new effective_date: effective_date, price: price, product_detail_id: product_detail_id, attr_importing_data: true, cost: cost
              if !price_list.valid?
                error_messages << price_list.errors.inspect
                error_messages << "invalid index => #{idx}"
                error = true
              elsif new_cost_list.present? && !new_cost_list.valid?
                error_messages << new_cost_list.errors.inspect
                error_messages << "invalid index => #{idx}"
                error = true                
              else
                price_lists << price_list
                if new_cost_list.present? && added_new_cost_lists.select{|added_new_cost_list| added_new_cost_list.effective_date == effective_date && added_new_cost_list.product_id == product_id}.blank?
                  new_cost_lists << new_cost_list
                  added_new_cost_lists << new_cost_list
                end
              end
            rescue Exception => e
              error_messages << e.inspect
              error_messages << "invalid index => #{idx}, product_detail_id => #{product_detail_id}, product_id => #{product_id}, cost => #{cost}"
              error = true
            end
          end
        end
      end
      if error
        error_messages.each_with_index do |error_message, idx|
          puts "#{idx+1}. #{error_message}"
        end
      else
        ActiveRecord::Base.transaction do
          begin
            CostList.import(new_cost_lists)
            PriceList.import(price_lists)
          rescue Exception => e
            puts "error => #{e.inspect}"
            raise ActiveRecord::Rollback
          end
        end
      end
    elsif type.eql?("product colors")
      start_from = step * 99999 - 99999 + 2 + step - 1
      end_at = step * 99999 + 2 + step - 1
      error = false
      error_messages = []
      product_colors = []
      added_product_colors = []
      workbook = Creek::Book.new Rails.root.join("public", filename).to_s
      worksheets = workbook.sheets

      worksheets.each do |worksheet|
        worksheet.rows.each_with_index do |row, idx|  
          next if idx < start_from
          break if idx > end_at
          if row.present?
            puts "index => #{idx}"
            product_id = 0
            color_id = 0
            begin
              product_id = Product.select(:id).where(code: row["A#{idx + 1}"].strip).first.id
              color_id = Color.select(:id).where(code: row["B#{idx + 1}"].strip).first.id              
              if ProductColor.select("1 AS one").where(["product_id = ? AND color_id = ?", product_id, color_id]).blank?
                product_color = ProductColor.new product_id: product_id, color_id: color_id, attr_importing_data: true
                unless product_color.valid?
                  error_messages << product_color.errors.inspect
                  error_messages << "invalid index => #{idx}"
                  error = true
                else
                  if added_product_colors.select{|added_product_color| added_product_color.product_id == product_id && added_product_color.color_id == color_id}.blank?
                    product_colors << product_color 
                    added_product_colors << product_color 
                  end
                end
              end
            rescue Exception => e
              error_messages << e.inspect
              error_messages << "invalid index => #{idx}, product_id => #{product_id}, color_id => #{color_id}"
              error = true
            end
          end
        end
      end
      if error
        error_messages.each_with_index do |error_message, idx|
          puts "#{idx+1}. #{error_message}"
        end
      else
        begin
          ProductColor.import(product_colors)
        rescue Exception => e
          puts "error => #{e.inspect}"
        end
      end
    elsif type.eql?("product barcodes")
      start_from = step * 99999 - 99999 + 2 + step - 1
      end_at = step * 99999 + 2 + step - 1
      error = false
      error_messages = []
      product_barcodes = []
      added_product_barcodes = []
      workbook = Creek::Book.new Rails.root.join("public", filename).to_s
      worksheets = workbook.sheets

      worksheets.each do |worksheet|
        worksheet.rows.each_with_index do |row, idx|  
          next if idx < start_from
          break if idx > end_at
          if row.present?
            puts "index => #{idx}"
            product_color_id = 0
            size_group_id = 0
            size_id = 0
            begin
              product_color = ProductColor.select(:id, "products.size_group_id").joins(:product, :color).where(["products.code = ? AND common_fields.code = ?", row["A#{idx + 1}"], row["B#{idx + 1}"]]).first
              product_color_id = product_color.id
              size_group_id = product_color.size_group_id
              size_id = Size.select(:id).where(size: row["C#{idx + 1}"], size_group_id: size_group_id).first.id
              barcode = if row["D#{idx + 1}"].blank?
                pb = ProductBarcode.where(["barcode LIKE ?", "1S%"]).select(:barcode).order("barcode DESC").first
                if pb.present?
                  "1S#{pb.barcode.split("1S")[1].succ}"
                else
                  "1S00001"
                end
              elsif ProductBarcode.select("1 AS one").where(barcode: row["D#{idx + 1}"]).blank?
                row["D#{idx + 1}"].strip
              else
                pb = ProductBarcode.where(["barcode LIKE ?", "1S%"]).select(:barcode).order("barcode DESC").first
                if pb.present?
                  "1S#{pb.barcode.split("1S")[1].succ}"
                else
                  "1S00001"
                end
              end
              product_barcode = ProductBarcode.new product_color_id: product_color_id, size_id: size_id, barcode: barcode
              unless product_barcode.valid?
                error_messages << product_barcode.errors.inspect
                error_messages << "invalid index => #{idx}"
                error = true
              else
                if added_product_barcodes.select{|added_product_barcode| added_product_barcode.barcode == barcode}.blank?
                  product_barcodes << product_barcode
                  added_product_barcodes << product_barcode
                end
              end
            rescue Exception => e
              error_messages << e.inspect
              error_messages << "invalid index => #{idx}, product_color_id => #{product_color_id}, size_group_id => #{size_group_id}, size_id => #{size_id}"
              error = true
            end
          end
        end
      end
      if error
        error_messages.each_with_index do |error_message, idx|
          puts "#{idx+1}. #{error_message}"
        end
      else
        begin
          ProductBarcode.import(product_barcodes)
        rescue Exception => e
          puts "error => #{e.inspect}"
        end
      end
    elsif type.eql?("warehouse")
      start_from = step * 10000 - 10000 + 2 + step - 1
      end_at = step * 10000 + 2 + step - 1
      error = false
      error_messages = []
      area_manager_id = Supervisor.select(:id).where(code: "ARY").first.id
      ActiveRecord::Base.transaction do
        workbook = Creek::Book.new Rails.root.join("public", "import warehouse table format.xlsx").to_s
        worksheets = workbook.sheets

        worksheets.each do |worksheet|
          worksheet.rows.each_with_index do |row, idx|
            if row.present? && idx >= start_from && idx <= end_at
              region_id = 0
              price_code_id = 0
              begin
                region_id = Region.select(:id).where(code: row["E#{idx + 1}"]).first.id
                price_code_id = PriceCode.select(:id).where(code: row["F#{idx + 1}"]).first.id
                address = if row["C#{idx + 1}"].present?
                  row["C#{idx + 1}"].strip
                else
                  "-"
                end
                warehouse = Warehouse.new code: row["A#{idx + 1}"], name: row["B#{idx + 1}"], address: address, supervisor_id: area_manager_id, region_id: region_id, warehouse_type: row["G#{idx + 1}"], price_code_id: price_code_id, first_message: row["I#{idx + 1}"], second_message: row["J#{idx + 1}"], third_message: row["K#{idx + 1}"], fourth_message: row["L#{idx + 1}"], fifth_message: row["M#{idx + 1}"], sku: row["H#{idx + 1}"]
                unless warehouse.save
                  error_messages << warehouse.errors.inspect
                  error_messages << "invalid index => #{idx}"
                  error = true
                end
              rescue Exception => e
                error_messages << e.inspect
                error_messages << "invalid index => #{idx}, region_id => #{region_id}, price_code_id => #{price_code_id}"
                error = true
              end
            end
          end
        end
        if error
          error_messages.each_with_index do |error_message, idx|
            puts "#{idx+1}. #{error_message}"
          end
          raise ActiveRecord::Rollback
        end
      end
    elsif type.eql?("counter event")
      start_from = step * 10000 - 10000 + 2 + step - 1
      end_at = step * 10000 + 2 + step - 1
      error = false
      error_messages = []
      ActiveRecord::Base.transaction do
        workbook = Creek::Book.new Rails.root.join("public", "import counter event table format.xlsx").to_s
        worksheets = workbook.sheets

        worksheets.each do |worksheet|
          worksheet.rows.each_with_index do |row, idx|
            if row.present? && idx >= start_from && idx <= end_at
              begin
                hash_params = if row["G#{idx + 1}"].strip.eql?("%")
                  counter_event_type = "Discount(%)"
                  second_discount = if row["I#{idx + 1}"] == 0
                    nil
                  else
                    row["I#{idx + 1}"]
                  end
                  name = if row["B#{idx + 1}"].present?
                    row["B#{idx + 1}"]
                  else
                    row["A#{idx + 1}"]
                  end
                  {code: row["A#{idx + 1}"], name: name, start_time: row["C#{idx + 1}"].to_date, end_time: row["D#{idx + 1}"].to_date, first_discount: row["H#{idx + 1}"], second_discount: second_discount, margin: row["E#{idx + 1}"], participation: row["F#{idx + 1}"], counter_event_type: counter_event_type}
                else
                  counter_event_type = ""
                  {}
                end
                counter_event = CounterEvent.new hash_params
                counter_event.attr_importing_data = true
                unless counter_event.save
                  error_messages << counter_event.errors.inspect
                  error_messages << "invalid index => #{idx}"
                  error = true
                end
              rescue Exception => e
                error_messages << e.inspect
                error_messages << "invalid index => #{idx}"
                error = true
              end
            end
          end
        end
        if error
          error_messages.each_with_index do |error_message, idx|
            puts "#{idx+1}. #{error_message}"
          end
          raise ActiveRecord::Rollback
        end
      end
    elsif type.eql?("counter event warehouse")
      start_from = step * 10000 - 10000 + 2 + step - 1
      end_at = step * 10000 + 2 + step - 1
      error = false
      error_messages = []
      ActiveRecord::Base.transaction do
        workbook = Creek::Book.new Rails.root.join("public", "import counter event warehouse table format.xlsx").to_s
        worksheets = workbook.sheets

        worksheets.each do |worksheet|
          worksheet.rows.each_with_index do |row, idx|
            if row.present? && idx >= start_from && idx <= end_at
              counter_event_id = 0
              warehouse_id = 0
              begin
                counter_event_id = CounterEvent.select(:id).where(["code = ? AND start_time = ? AND end_time = ?", row["A#{idx + 1}"].upcase.gsub(" ","").gsub("\t",""), Time.zone.parse(row["C#{idx + 1}"]), Time.zone.parse(row["D#{idx + 1}"])]).first.id
                warehouse_id = Warehouse.select(:id).where(code: row["B#{idx + 1}"]).first.id
                counter_event_warehouse = CounterEventWarehouse.new counter_event_id: counter_event_id, warehouse_id: warehouse_id
                unless counter_event_warehouse.save
                  error_messages << counter_event_warehouse.errors.inspect
                  error_messages << "invalid index => #{idx}"
                  error = true
                end
              rescue Exception => e
                error_messages << e.inspect
                error_messages << "invalid index => #{idx}, counter_event_id => #{counter_event_id}, warehouse_id => #{warehouse_id}"
                error = true
              end
            end
          end
        end
        if error
          error_messages.each_with_index do |error_message, idx|
            puts "#{idx+1}. #{error_message}"
          end
          raise ActiveRecord::Rollback
        end
      end
    elsif type.eql?("consignment sale")
      # import per 10000 row
      start_from = step * 9999 - 9999 + 2 + step - 1
      end_at = step * 9999 + 2 + step - 1
      error = false
      error_messages = []
      skipped_trans_number = []
      skipped_trans_number_null_event_codes = []
      skipped_trans_number_no_events = []
      consignment_sales = []
      workbook = Creek::Book.new Rails.root.join("public", "import consignment sales.xlsx").to_s
      worksheets = workbook.sheets

      worksheets.each do |worksheet|
        worksheet.rows.each_with_index do |row, idx|
          next if idx < start_from
          break if idx > end_at
          if row.present? && idx >= start_from && idx <= end_at
            puts "index => #{idx}"
            if row["G#{idx + 1}"] != "S" && row["G#{idx + 1}"] != "NULL"
              counter_event_id = 0
              warehouse_id = 0
              no_sale = if row["H#{idx + 1}"].present? && row["H#{idx + 1}"].downcase.strip.eql?("sale")
                false
              else
                true
              end
              counter_event_id = if row["G#{idx + 1}"].present? && !row["G#{idx + 1}"].strip.include?("SP") && !row["G#{idx + 1}"].strip.eql?("N") && !no_sale
                CounterEvent.select(:id).where(["code = ? AND start_time <= ? AND end_time >= ?", row["G#{idx + 1}"].upcase.gsub(" ","").gsub("\t",""), Time.zone.parse(row["A#{idx + 1}"]).end_of_day, Time.zone.parse(row["A#{idx + 1}"])]).first.id
              else
                nil
              end
              warehouse = Warehouse.select(:id, :code).counter.where(code: row["F#{idx + 1}"]).first
              if warehouse.present?
                if row["E#{idx + 1}"].to_f > 0
                  warehouse_id = warehouse.id
                  is_sale_approved = if row["B#{idx + 1}"] == 1
                    true
                  else
                    false
                  end
                
                  consignment_sale = ConsignmentSale.new transaction_date: row["A#{idx + 1}"].to_date, approved: is_sale_approved, transaction_number: row["C#{idx + 1}"], total: row["E#{idx + 1}"], warehouse_id: warehouse_id, counter_event_id: counter_event_id, no_sale: no_sale, attr_warehouse_code: warehouse.code, attr_importing_data: true
                  unless consignment_sale.valid?
                    error_messages << consignment_sale.errors.inspect
                    error_messages << "invalid index => #{idx}"
                    error = true
                  else
                    consignment_sales << consignment_sale
                  end
                else
                  skipped_trans_number << row["C#{idx + 1}"] unless skipped_trans_number.include?(row["C#{idx + 1}"])
                end
              else
                skipped_trans_number << row["C#{idx + 1}"] unless skipped_trans_number.include?(row["C#{idx + 1}"])
              end
            else
              skipped_trans_number_null_event_codes << row["C#{idx + 1}"] if !skipped_trans_number_null_event_codes.include?(row["C#{idx + 1}"]) && row["G#{idx + 1}"] == "NULL"
              skipped_trans_number_no_events << row["C#{idx + 1}"] if !skipped_trans_number_no_events.include?(row["C#{idx + 1}"]) && row["G#{idx + 1}"] == "S"
            end
          end
        end
      end
      if error
        error_messages.each_with_index do |error_message, idx|
          puts "#{idx+1}. #{error_message}"
        end
      else
        begin
          ConsignmentSale.import(consignment_sales)          
          puts "skipped numbers => #{skipped_trans_number.to_sentence}" if skipped_trans_number.present?
          puts "skipped numbers (event NULL) => #{skipped_trans_number_null_event_codes.to_sentence}" if skipped_trans_number_null_event_codes.present?
          puts "skipped numbers (no event) => #{skipped_trans_number_no_events.to_sentence}" if skipped_trans_number_no_events.present?
        rescue Exception => e
          puts "error => #{e.inspect}"
        end
      end
    elsif type.eql?("consignment sale (skipped)")
      # import per 10000 row
      start_from = step * 9999 - 9999 + 2 + step - 1
      end_at = step * 9999 + 2 + step - 1
      error = false
      error_messages = []
      consignment_sales = []
      workbook = Creek::Book.new Rails.root.join("public", "import consignment sales.xlsx").to_s
      worksheets = workbook.sheets

      worksheets.each do |worksheet|
        worksheet.rows.each_with_index do |row, idx|
          next if idx < start_from
          break if idx > end_at
          if row.present? && idx >= start_from && idx <= end_at && ConsignmentSale.select("1 AS one").where(transaction_number: row["C#{idx + 1}"]).blank?
            puts "index => #{idx}"
            counter_event_id = 0
            warehouse_id = 0
            no_sale = if row["H#{idx + 1}"].present? && row["H#{idx + 1}"].downcase.strip.eql?("sale")
              false
            else
              true
            end

            is_sale_approved = if row["B#{idx + 1}"] == 1
              true
            else
              false
            end
                
            begin
              counter_event = nil
              counter_event_id = if row["G#{idx + 1}"].present? && !row["G#{idx + 1}"].strip.include?("SP") && !row["G#{idx + 1}"].strip.eql?("N") && !row["G#{idx + 1}"].strip.eql?("S") && row["E#{idx + 1}"] != "K02403170034" && !no_sale
                (counter_event = CounterEvent.select(:id, :counter_event_type, :first_discount).where(["code = ? AND start_time <= ? AND end_time >= ?", row["G#{idx + 1}"].upcase.gsub(" ","").gsub("\t",""), Time.zone.parse(row["A#{idx + 1}"]).end_of_day, Time.zone.parse(row["A#{idx + 1}"])]).first).id
              else
                nil
              end
              warehouse = Warehouse.select(:id, :code).counter.where(code: row["F#{idx + 1}"]).first
              if warehouse.present?
                warehouse_id = warehouse.id                
                # satu row yang aneh sendiri
                if row["E#{idx + 1}"] == "K02403170034"
                  consignment_sale = ConsignmentSale.new transaction_date: row["A#{idx + 1}"].to_date, approved: is_sale_approved, transaction_number: row["C#{idx + 1}"], total: row["D#{idx + 1}"], warehouse_id: warehouse_id, counter_event_id: counter_event_id, no_sale: no_sale, attr_warehouse_code: warehouse.code, attr_importing_data: true
                  unless consignment_sale.valid?
                    error_messages << consignment_sale.errors.inspect
                    error_messages << "invalid index => #{idx}"
                    error = true
                  else
                    consignment_sales << consignment_sale
                  end
                elsif row["E#{idx + 1}"].to_f == 0
                  if !counter_event.counter_event_type.eql?("Discount(%)") || counter_event.first_discount.to_f != 100
                    error_messages << "discount != 100%"
                    error_messages << "invalid index => #{idx}"
                    error = true
                  else
                    consignment_sale = ConsignmentSale.new transaction_date: row["A#{idx + 1}"].to_date, approved: is_sale_approved, transaction_number: row["C#{idx + 1}"], total: row["E#{idx + 1}"], warehouse_id: warehouse_id, counter_event_id: counter_event_id, no_sale: no_sale, attr_warehouse_code: warehouse.code, attr_importing_data: true
                    unless consignment_sale.valid?
                      error_messages << consignment_sale.errors.inspect
                      error_messages << "invalid index => #{idx}"
                      error = true
                    else
                      consignment_sales << consignment_sale
                    end
                  end
                elsif row["G#{idx + 1}"].present? && row["G#{idx + 1}"].strip.eql?("S")
                  consignment_sale = ConsignmentSale.new transaction_date: row["A#{idx + 1}"].to_date, approved: is_sale_approved, transaction_number: row["C#{idx + 1}"], total: row["E#{idx + 1}"], warehouse_id: warehouse_id, counter_event_id: counter_event_id, no_sale: no_sale, attr_warehouse_code: warehouse.code, attr_importing_data: true
                  unless consignment_sale.valid?
                    error_messages << consignment_sale.errors.inspect
                    error_messages << "invalid index => #{idx}"
                    error = true
                  else
                    consignment_sales << consignment_sale
                  end
                end
              end
            rescue Exception => e
              error_messages << e.inspect
              error_messages << "invalid index => #{idx}, counter_event_id => #{counter_event_id}, warehouse_id => #{warehouse_id}"
              error = true
            end
          end
        end
      end
      if error
        error_messages.each_with_index do |error_message, idx|
          puts "#{idx+1}. #{error_message}"
        end
      else
        begin
          ConsignmentSale.import(consignment_sales)          
        rescue Exception => e
          puts "error => #{e.inspect}"
        end
      end
    end
  end
end
