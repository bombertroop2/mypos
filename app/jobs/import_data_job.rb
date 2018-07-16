class ImportDataJob < ApplicationJob
  queue_as :default

  def perform(type, step=1)
    if type.eql?("product")
      error = false
      ActiveRecord::Base.transaction do
        workbook = Creek::Book.new Rails.root.join("public", "import product table format.xlsx").to_s
        worksheets = workbook.sheets

        worksheets.each do |worksheet|
          worksheet.rows.each_with_index do |row, idx|          
            brand_id = 0
            sex = ""
            target = ""
            model_id = 0
            goods_type_id = 0
            size_group_id = 0
            if row.present? && idx > 1
              begin          
                brand_id = Brand.select(:id).where(code: row["B#{idx + 1}"].strip).first.id
                sex = Product::SEX.select{ |x| x[1] == (row["C#{idx + 1}"].strip.eql?("B") ? "ladies" : row["C#{idx + 1}"].strip.downcase) }.first.first.downcase
                vendor_id = Vendor.select(:id).where(code: row["D#{idx + 1}"].strip).first.id
                target = Product::TARGETS.select{ |x| x[1] == row["E#{idx + 1}"].strip.downcase }.first.first.downcase
                model_id = Model.select(:id).where(code: row["F#{idx + 1}"].strip).first.id
                goods_type_id = GoodsType.select(:id).where(code: row["G#{idx + 1}"].strip).first.id
                size_group_id = SizeGroup.select(:id).where(code: row["H#{idx + 1}"].strip).first.id
                product = Product.new code: row["A#{idx + 1}"].strip, brand_id: brand_id, sex: sex, vendor_id: vendor_id, target: target, model_id: model_id, goods_type_id: goods_type_id, size_group_id: size_group_id, additional_information: (row["I#{idx + 1}"].present? ? row["I#{idx + 1}"].strip : nil)
                product.attr_importing_data = true
                unless product.save
                  puts product.errors.inspect
                  puts "invalid index => #{idx}"
                  #                  ImportDataEmailJob.perform_later("import product", product.errors.inspect, "invalid index => #{idx}")
                  error = true
                  break
                end
              rescue Exception => e
                puts e.inspect
                puts "invalid index => #{idx}, brand id => #{brand_id}, sex => #{sex}, vendor_id => #{vendor_id}, target => #{target}, model_id => #{model_id}, goods_type_id => #{goods_type_id}, size_group_id => #{size_group_id}"
                #                ImportDataEmailJob.perform_later("import product", e.inspect, "invalid index => #{idx}, brand id => #{brand_id}, sex => #{sex}, vendor_id => #{vendor_id}, target => #{target}, model_id => #{model_id}, goods_type_id => #{goods_type_id}, size_group_id => #{size_group_id}")
                error = true
                break
              end
            end
          end
          break if error
        end
        if error
          raise ActiveRecord::Rollback
          #        else
          #          ImportDataEmailJob.perform_later("import product", nil, nil)
        end
      end
    elsif type.eql?("product detail")
      error = false
      ActiveRecord::Base.transaction do
        workbook = Creek::Book.new Rails.root.join("public", "import product detail table format.xlsx").to_s
        worksheets = workbook.sheets

        worksheets.each do |worksheet|
          worksheet.rows.each_with_index do |row, idx|          
            size_id = 0
            product_id = 0
            price_code_id = 0
            if row.present? && idx > 1
              begin          
                product = Product.select(:id, :size_group_id).where(code: row["B#{idx + 1}"].strip).first
                #                if product.present?
                size_group_id = product.size_group_id
                size_id = Size.select(:id).where(size: row["A#{idx + 1}"].to_s.strip.split(".")[0], size_group_id: size_group_id).first.id
                product_id = product.id
                price_code_id = PriceCode.select(:id).where(code: row["C#{idx + 1}"].strip).first.id
                #                  if ProductDetail.select("1 AS one").where(size_id: size_id, product_id: product_id, price_code_id: price_code_id).blank?
                product_detail = ProductDetail.new size_id: size_id, product_id: product_id, price_code_id: price_code_id
                product_detail.size_group_id = size_group_id
                product_detail.user_is_adding_new_product = true
                product_detail.attr_importing_data = true
                unless product_detail.save
                  puts product_detail.errors.inspect
                  puts "invalid index => #{idx}"
                  error = true
                  break
                end
                #                  end
                #                end
              rescue Exception => e
                puts e.inspect
                puts "invalid index => #{idx}, size id => #{size_id}, product_id => #{product_id}, size_group_id => #{size_group_id}, price_code_id => #{price_code_id}"
                error = true
                break
              end
            end
          end
          break if error
        end
        if error
          raise ActiveRecord::Rollback
        end
      end
    elsif type.eql?("product detail bag. 2")
      error = false
      ActiveRecord::Base.transaction do
        workbook = Creek::Book.new Rails.root.join("public", "daftar product detail yang di skip.xlsx").to_s
        worksheets = workbook.sheets

        worksheets.each do |worksheet|
          worksheet.rows.each_with_index do |row, idx|          
            size_id = 0
            product_id = 0
            price_code_id = 0
            if row.present? && idx > 1
              begin          
                product = Product.select(:id, :size_group_id).where(code: row["B#{idx + 1}"].strip).first
                if product.present?
                  size_group_id = product.size_group_id
                  size_id = Size.select(:id).where(size: row["A#{idx + 1}"].to_s.strip.split(".")[0], size_group_id: size_group_id).first.id
                  product_id = product.id
                  price_code_id = PriceCode.select(:id).where(code: row["C#{idx + 1}"].strip).first.id
                  product_detail = ProductDetail.new size_id: size_id, product_id: product_id, price_code_id: price_code_id
                  product_detail.size_group_id = size_group_id
                  product_detail.user_is_adding_new_product = true
                  product_detail.attr_importing_data = true
                  unless product_detail.save
                    puts product_detail.errors.inspect
                    puts "invalid index => #{idx}"
                    error = true
                    break
                  end
                end
              rescue Exception => e
                puts e.inspect
                puts "invalid index => #{idx}, size id => #{size_id}, product_id => #{product_id}, size_group_id => #{size_group_id}, price_code_id => #{price_code_id}"
                error = true
                break
              end
            end
          end
          break if error
        end
        if error
          raise ActiveRecord::Rollback
        end
      end
    elsif type.eql?("product costs")
      error = false
      ActiveRecord::Base.transaction do
        workbook = Creek::Book.new Rails.root.join("public", "import product cost table format.xlsx").to_s
        worksheets = workbook.sheets

        worksheets.each do |worksheet|
          worksheet.rows.each_with_index do |row, idx|
            product_id = 0
            if row.present? && idx > 1
              begin
                product_id = Product.select(:id).where(code: row["A#{idx + 1}"]).first.id
                cost_list = CostList.new effective_date: row["B#{idx + 1}"].strftime("%d/%m/%Y").to_date, cost: row["C#{idx + 1}"], product_id: product_id
                cost_list.attr_importing_data = true
                unless cost_list.save
                  puts cost_list.errors.inspect
                  puts "invalid index => #{idx}"
                  error = true
                  break
                end
              rescue Exception => e
                puts e.inspect
                puts "invalid index => #{idx}, product_id => #{product_id}"
                error = true
                break
              end
            end
          end
          break if error
        end
        if error
          raise ActiveRecord::Rollback
        end
      end
    elsif type.eql?("product costs bag. 2")
      error = false
      ActiveRecord::Base.transaction do
        workbook = Creek::Book.new Rails.root.join("public", "missing costs.xlsx").to_s
        worksheets = workbook.sheets

        worksheets.each do |worksheet|
          worksheet.rows.each_with_index do |row, idx|
            product_id = 0
            if row.present? && idx > 1
              begin
                product_id = Product.select(:id).where(code: row["A#{idx + 1}"]).first.id
                cost_list = CostList.new effective_date: row["B#{idx + 1}"].strftime("%d/%m/%Y").to_date, cost: row["C#{idx + 1}"], product_id: product_id
                cost_list.attr_importing_data = true
                unless cost_list.save
                  puts cost_list.errors.inspect
                  puts "invalid index => #{idx}"
                  error = true
                  break
                end
              rescue Exception => e
                puts e.inspect
                puts "invalid index => #{idx}, product_id => #{product_id}"
                error = true
                break
              end
            end
          end
          break if error
        end
        if error
          raise ActiveRecord::Rollback
        end
      end
    elsif type.eql?("product costs bag. 3")
      error = false
      ActiveRecord::Base.transaction do
        workbook = Creek::Book.new Rails.root.join("public", "daftar cost yang di skip.xlsx").to_s
        worksheets = workbook.sheets

        worksheets.each do |worksheet|
          worksheet.rows.each_with_index do |row, idx|
            product_id = 0
            if row.present? && idx > 1
              begin
                product_id = Product.select(:id).where(code: row["A#{idx + 1}"]).first.id
                cost_list = CostList.new effective_date: row["B#{idx + 1}"].strftime("%d/%m/%Y").to_date, cost: row["C#{idx + 1}"], product_id: product_id
                cost_list.attr_importing_data = true
                unless cost_list.save
                  puts cost_list.errors.inspect
                  puts "invalid index => #{idx}"
                  error = true
                  break
                end
              rescue Exception => e
                puts e.inspect
                puts "invalid index => #{idx}, product_id => #{product_id}"
                error = true
                break
              end
            end
          end
          break if error
        end
        if error
          raise ActiveRecord::Rollback
        end
      end
    elsif type.eql?("product prices")
      start_from = step * 10000 - 10000 + 2 + step - 1
      end_at = step * 10000 + 2 + step - 1
      workbook = Creek::Book.new Rails.root.join("public", "import price list table format.xlsx").to_s
      worksheets = workbook.sheets

      error = false
      error_messages = []
      ActiveRecord::Base.transaction do
        worksheets.each do |worksheet|
          worksheet.rows.each_with_index do |row, idx|
            if row.present? && idx >= start_from && idx <= end_at
              product_detail_id = 0
              product_id = 0
              cost = 0
              begin
                product_detail = ProductDetail.select(:id, :product_id).joins(:size, :product, :price_code).where(["sizes.size_group_id = products.size_group_id AND sizes.size = ? AND products.code = ? AND common_fields.code = ?", row["A#{idx + 1}"].to_s.strip.split(".")[0], row["B#{idx + 1}"], row["C#{idx + 1}"]]).first
                product_detail_id = product_detail.id
                product_id = product_detail.product_id
                price = row["E#{idx + 1}"] <= 0 ? 1 : row["E#{idx + 1}"]
                effective_date = row["D#{idx + 1}"].strftime("%d/%m/%Y").to_date
                cost = CostList.select(:cost).where(["effective_date = ? AND product_id = ?", effective_date, product_id]).first.cost
                price_list = PriceList.new effective_date: effective_date, price: price, product_detail_id: product_detail_id
                price_list.attr_importing_data = true
                price_list.cost = cost
                unless price_list.save
                  error_messages << price_list.errors.inspect
                  error_messages << "invalid index => #{idx}"
                  error = true
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
          raise ActiveRecord::Rollback
        end
      end
    elsif type.eql?("product prices bag. 2")
      error = false
      error_messages = []
      ActiveRecord::Base.transaction do
        workbook = Creek::Book.new Rails.root.join("public", "daftar price yang di skip.xlsx").to_s
        worksheets = workbook.sheets

        worksheets.each do |worksheet|
          worksheet.rows.each_with_index do |row, idx|
            product_detail_id = 0
            product_id = 0
            cost = 0
            if row.present? && idx > 1
              begin
                product_detail = ProductDetail.select(:id, :product_id).joins(:size, :product, :price_code).where(["sizes.size_group_id = products.size_group_id AND sizes.size = ? AND products.code = ? AND common_fields.code = ?", row["A#{idx + 1}"].to_s.strip.split(".")[0], row["B#{idx + 1}"], row["C#{idx + 1}"]]).first
                product_detail_id = product_detail.id
                product_id = product_detail.product_id
                price = row["E#{idx + 1}"] <= 0 ? 1 : row["E#{idx + 1}"]
                effective_date = row["D#{idx + 1}"].strftime("%d/%m/%Y").to_date
                cost = CostList.select(:cost).where(["effective_date = ? AND product_id = ?", effective_date, product_id]).first.cost
                price_list = PriceList.new effective_date: effective_date, price: price, product_detail_id: product_detail_id
                price_list.attr_importing_data = true
                price_list.cost = cost
                unless price_list.save
                  error_messages << price_list.errors.inspect
                  error_messages << "invalid index => #{idx}"
                  error = true
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
          raise ActiveRecord::Rollback
        end
      end
    elsif type.eql?("product colors")
      start_from = step * 10000 - 10000 + 2 + step - 1
      end_at = step * 10000 + 2 + step - 1
      error = false
      error_messages = []
      ActiveRecord::Base.transaction do
        workbook = Creek::Book.new Rails.root.join("public", "import product color table format.xlsx").to_s
        worksheets = workbook.sheets

        worksheets.each do |worksheet|
          worksheet.rows.each_with_index do |row, idx|
            if row.present? && idx >= start_from && idx <= end_at
              product_id = 0
              color_id = 0
              begin
                product_id = Product.select(:id).where(code: row["A#{idx + 1}"]).first.id
                color_id = Color.select(:id).where(code: row["B#{idx + 1}"]).first.id
                product_color = ProductColor.new product_id: product_id, color_id: color_id
                product_color.attr_importing_data = true
                unless product_color.save
                  error_messages << product_color.errors.inspect
                  error_messages << "invalid index => #{idx}"
                  error = true
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
          raise ActiveRecord::Rollback
        end
      end
    elsif type.eql?("product barcodes")
      start_from = step * 10000 - 10000 + 2 + step - 1
      end_at = step * 10000 + 2 + step - 1
      error = false
      error_messages = []
      ActiveRecord::Base.transaction do
        workbook = Creek::Book.new Rails.root.join("public", "import product barcode table format.xlsx").to_s
        worksheets = workbook.sheets

        worksheets.each do |worksheet|
          worksheet.rows.each_with_index do |row, idx|
            if row.present? && idx >= start_from && idx <= end_at
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
                  row["D#{idx + 1}"]
                else
                  pb = ProductBarcode.where(["barcode LIKE ?", "1S%"]).select(:barcode).order("barcode DESC").first
                  if pb.present?
                    "1S#{pb.barcode.split("1S")[1].succ}"
                  else
                    "1S00001"
                  end
                end
                product_barcode = ProductBarcode.new product_color_id: product_color_id, size_id: size_id, barcode: barcode
                unless product_barcode.save
                  error_messages << product_barcode.errors.inspect
                  error_messages << "invalid index => #{idx}"
                  error = true
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
          raise ActiveRecord::Rollback
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
    end
  end
end
