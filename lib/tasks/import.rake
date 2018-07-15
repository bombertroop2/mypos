namespace :import do
  desc "Import Regions from Excel"
  task regions: :environment do 
    workbook = Creek::Book.new Rails.root.join("public", "import region table format.xlsx").to_s
    worksheets = workbook.sheets

    worksheets.each do |worksheet|
      worksheet.rows.each_with_index do |row, idx|
        if row.present? && idx > 1
          if row["D#{idx + 1}"].present?
            hash_params = {code: row["A#{idx + 1}"], name: row["B#{idx + 1}"], type: "Region", description: row["D#{idx + 1}"]}
          else
            hash_params = {code: row["A#{idx + 1}"], name: row["B#{idx + 1}"], type: "Region"}
          end
          region = Region.new hash_params
          region.save
        end
      end
    end
  end
  
  desc "Import Colors from Excel"
  task colors: :environment do 
    workbook = Creek::Book.new Rails.root.join("public", "Color.xlsx").to_s
    worksheets = workbook.sheets

    worksheets.each do |worksheet|
      worksheet.rows.each_with_index do |row, idx|
        if row.present? && idx > 1
          if row["D#{idx + 1}"].present?
            hash_params = {code: row["A#{idx + 1}"], name: row["B#{idx + 1}"], type: row["C#{idx + 1}"], description: row["D#{idx + 1}"]}
          else
            hash_params = {code: row["A#{idx + 1}"], name: row["B#{idx + 1}"], type: row["C#{idx + 1}"]}
          end
          color = Color.new hash_params
          puts "color #{row["A#{idx + 1}"]} invalid" unless color.save
        end
      end
    end
  end
    
  desc "Import Colors bag.2 from Excel"
  task colors_part_2: :environment do
    workbook = Creek::Book.new Rails.root.join("public", "Color2.xlsx").to_s
    worksheets = workbook.sheets

    error_row = ""
    ActiveRecord::Base.transaction do
      worksheets.each do |worksheet|
        worksheet.rows.each_with_index do |row, idx|
          if row.present? && idx > 1
            begin
              color = Color.new code: row["A#{idx + 1}"], name: row["B#{idx + 1}"], type: row["C#{idx + 1}"], description: row["D#{idx + 1}"]
              unless color.save
                puts color.errors.inspect
                error_row = "invalid index => #{idx}"
                break
              end
            rescue Exception => e
              puts e.inspect
              error_row = "invalid index => #{idx}"
              break
            end
          end
        end
        break if error_row.present?
      end
      if error_row.present?
        puts error_row
        raise ActiveRecord::Rollback
      end
    end
  end  

  desc "Import Size Groups from Excel"
  task size_groups: :environment do 
    workbook = Creek::Book.new Rails.root.join("public", "import size group table format.xlsx").to_s
    worksheets = workbook.sheets

    worksheets.each do |worksheet|
      worksheet.rows.each_with_index do |row, idx|
        if row.present? && idx > 1
          if row["B#{idx + 1}"].present?
            hash_params = {code: row["A#{idx + 1}"], description: row["B#{idx + 1}"]}
          else
            hash_params = {code: row["A#{idx + 1}"]}
          end
          size_group = SizeGroup.new hash_params
          puts "size group #{row["A#{idx + 1}"]} invalid" unless size_group.save
        end
      end
    end
  end
  
  desc "Import Size Groups bag.2 from Excel"
  task size_groups_part_2: :environment do 
    workbook = Creek::Book.new Rails.root.join("public", "import size group table format bag. 2.xlsx").to_s
    worksheets = workbook.sheets

    worksheets.each do |worksheet|
      worksheet.rows.each_with_index do |row, idx|
        if row.present? && idx > 1
          if row["B#{idx + 1}"].present?
            hash_params = {code: row["A#{idx + 1}"], description: row["B#{idx + 1}"]}
          else
            hash_params = {code: row["A#{idx + 1}"]}
          end
          size_group = SizeGroup.new hash_params
          puts "size group #{row["A#{idx + 1}"]} invalid" unless size_group.save
        end
      end
    end
  end
  
  desc "Import Sizes from Excel"
  task sizes: :environment do 
    workbook = Creek::Book.new Rails.root.join("public", "import size table format.xlsx").to_s
    worksheets = workbook.sheets

    worksheets.each do |worksheet|
      worksheet.rows.each_with_index do |row, idx|
        if row.present? && idx > 1
          size_group_id = SizeGroup.select(:id).where(code: row["A#{idx + 1}"]).first.id
          size_value = row["B#{idx + 1}"].to_s.split(".")[0]
          size_order = row["C#{idx + 1}"].to_s.split(".")[0]
          size = Size.new size_group_id: size_group_id, size: size_value, size_order: size_order
          size.save
        end
      end
    end
  end
  
  desc "Import Sizes bag. 2 from Excel"
  task sizes_part_2: :environment do 
    workbook = Creek::Book.new Rails.root.join("public", "import size table format bag. 2.xlsx").to_s
    worksheets = workbook.sheets

    worksheets.each do |worksheet|
      worksheet.rows.each_with_index do |row, idx|
        if row.present? && idx > 1
          size_group_id = SizeGroup.select(:id).where(code: row["A#{idx + 1}"]).first.id
          size_value = row["B#{idx + 1}"].to_s.split(".")[0]
          size_order = row["C#{idx + 1}"].to_s.split(".")[0]
          size = Size.new size_group_id: size_group_id, size: size_value, size_order: size_order
          size.save
        end
      end
    end
  end

  desc "Import Vendors from Excel"
  task vendors: :environment do 
    workbook = Creek::Book.new Rails.root.join("public", "import vendors table format.xlsx").to_s
    worksheets = workbook.sheets

    worksheets.each do |worksheet|
      worksheet.rows.each_with_index do |row, idx|
        if row.present? && idx > 1
          is_taxable_entrepreneur = if row["E#{idx + 1}"].to_i == 1
            true
          else
            false
          end
          vendor = Vendor.new code: row["A#{idx + 1}"], name: row["B#{idx + 1}"], address: row["C#{idx + 1}"], terms_of_payment: row["D#{idx + 1}"].to_i, is_taxable_entrepreneur: is_taxable_entrepreneur, value_added_tax: row["F#{idx + 1}"], phone: row["G#{idx + 1}"], facsimile: row["H#{idx + 1}"], email: row["I#{idx + 1}"], pic_name: row["J#{idx + 1}"], pic_phone: row["K#{idx + 1}"], pic_mobile_phone: row["L#{idx + 1}"], pic_email: row["M#{idx + 1}"]
          vendor.save
        end
      end
    end
  end

  desc "Import Vendors bag.2 from Excel"
  task vendors_part_2: :environment do 
    workbook = Creek::Book.new Rails.root.join("public", "import vendors table format bag. 2.xlsx").to_s
    worksheets = workbook.sheets

    worksheets.each do |worksheet|
      worksheet.rows.each_with_index do |row, idx|
        if row.present? && idx > 1
          is_taxable_entrepreneur = if row["E#{idx + 1}"].to_i == 1
            true
          else
            false
          end
          vendor = Vendor.new code: row["A#{idx + 1}"], name: row["B#{idx + 1}"], address: row["C#{idx + 1}"], terms_of_payment: row["D#{idx + 1}"].to_i, is_taxable_entrepreneur: is_taxable_entrepreneur, value_added_tax: row["F#{idx + 1}"], phone: row["G#{idx + 1}"], facsimile: row["H#{idx + 1}"], email: row["I#{idx + 1}"], pic_name: row["J#{idx + 1}"], pic_phone: row["K#{idx + 1}"], pic_mobile_phone: row["L#{idx + 1}"], pic_email: row["M#{idx + 1}"]
          vendor.save
        end
      end
    end
  end

  desc "Import Brands from Excel"
  task brands: :environment do 
    workbook = Creek::Book.new Rails.root.join("public", "import brand table format.xlsx").to_s
    worksheets = workbook.sheets

    worksheets.each do |worksheet|
      worksheet.rows.each_with_index do |row, idx|
        if row.present? && idx > 1
          brand = Brand.new code: row["A#{idx + 1}"], name: row["B#{idx + 1}"], type: row["C#{idx + 1}"], description: row["D#{idx + 1}"]
          brand.save
        end
      end
    end
  end

  desc "Import Models from Excel"
  task models: :environment do 
    workbook = Creek::Book.new Rails.root.join("public", "import model table format.xlsx").to_s
    worksheets = workbook.sheets

    existed_models = []
    worksheets.each do |worksheet|
      worksheet.rows.each_with_index do |row, idx|
        if row.present? && idx > 1
          if Model.select("1 AS one").where(code: row["A#{idx + 1}"]).present?
            existed_models << row["A#{idx + 1}"]
          else
            model = Model.new code: row["A#{idx + 1}"], name: row["B#{idx + 1}"], type: row["C#{idx + 1}"], description: row["D#{idx + 1}"]
            model.save
          end
        end
      end
    end
    puts "Existed models => #{existed_models.to_sentence}"
  end

  desc "Import Goods Types from Excel"
  task goods_types: :environment do 
    workbook = Creek::Book.new Rails.root.join("public", "import goods types table format.xlsx").to_s
    worksheets = workbook.sheets

    worksheets.each do |worksheet|
      worksheet.rows.each_with_index do |row, idx|
        if row.present? && idx > 1
          goods_type = GoodsType.new code: row["A#{idx + 1}"], name: row["B#{idx + 1}"], type: row["C#{idx + 1}"], description: row["D#{idx + 1}"]
          goods_type.save
        end
      end
    end
  end

  desc "Import Product Details/Sizes from Excel"
  task product_details: :environment do
    workbook = Creek::Book.new Rails.root.join("public", "import product detail table format.xlsx").to_s
    worksheets = workbook.sheets

    error_row = ""
    ActiveRecord::Base.transaction do
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
                if ProductDetail.select("1 AS one").where(size_id: size_id, product_id: product_id, price_code_id: price_code_id).blank?
                  product_detail = ProductDetail.new size_id: size_id, product_id: product_id, price_code_id: price_code_id
                  product_detail.size_group_id = size_group_id
                  product_detail.user_is_adding_new_product = true
                  product_detail.attr_importing_data = true
                  unless product_detail.save
                    puts product_detail.errors.inspect
                    error_row = "invalid index => #{idx}"
                    break
                  end
                end
              end
            rescue Exception => e
              puts e.inspect
              error_row = "invalid index => #{idx}, size id => #{size_id}, product_id => #{product_id}, size_group_id => #{size_group_id}, price_code_id => #{price_code_id}"
              break
            end
          end
        end
        break if error_row.present?
      end
      if error_row.present?
        puts error_row
        raise ActiveRecord::Rollback
      end
    end
  end

  desc "Import Product Details/Sizes bag.2 from Excel"
  task product_details_part_2: :environment do
    workbook = Creek::Book.new Rails.root.join("public", "daftar product detail yang di skip.xlsx").to_s
    worksheets = workbook.sheets

    error_row = ""
    ActiveRecord::Base.transaction do
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
                  error_row = "invalid index => #{idx}"
                  break
                end
              end
            rescue Exception => e
              puts e.inspect
              error_row = "invalid index => #{idx}, size id => #{size_id}, product_id => #{product_id}, size_group_id => #{size_group_id}, price_code_id => #{price_code_id}"
              break
            end
          end
        end
        break if error_row.present?
      end
      if error_row.present?
        puts error_row
        raise ActiveRecord::Rollback
      end
    end
  end

  desc "Import Product Costs from Excel"
  task product_costs: :environment do
    workbook = Creek::Book.new Rails.root.join("public", "import product cost table format.xlsx").to_s
    worksheets = workbook.sheets

    error_row = ""
    ActiveRecord::Base.transaction do
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
                error_row = "invalid index => #{idx}"
                break
              end
            rescue Exception => e
              puts e.inspect
              error_row = "invalid index => #{idx}, product_id => #{product_id}"
              break
            end
          end
        end
        break if error_row.present?
      end
      if error_row.present?
        puts error_row
        raise ActiveRecord::Rollback
      end
    end
  end

  desc "Import Product Costs bag.2 from Excel"
  task product_costs_part_2: :environment do
    workbook = Creek::Book.new Rails.root.join("public", "missing costs.xlsx").to_s
    worksheets = workbook.sheets

    error_row = ""
    ActiveRecord::Base.transaction do
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
                error_row = "invalid index => #{idx}"
                break
              end
            rescue Exception => e
              puts e.inspect
              error_row = "invalid index => #{idx}, product_id => #{product_id}"
              break
            end
          end
        end
        break if error_row.present?
      end
      if error_row.present?
        puts error_row
        raise ActiveRecord::Rollback
      end
    end
  end

  desc "Import Product Costs bag.3 from Excel"
  task product_costs_part_3: :environment do
    workbook = Creek::Book.new Rails.root.join("public", "daftar cost yang di skip.xlsx").to_s
    worksheets = workbook.sheets

    error_row = ""
    ActiveRecord::Base.transaction do
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
                error_row = "invalid index => #{idx}"
                break
              end
            rescue Exception => e
              puts e.inspect
              error_row = "invalid index => #{idx}, product_id => #{product_id}"
              break
            end
          end
        end
        break if error_row.present?
      end
      if error_row.present?
        puts error_row
        raise ActiveRecord::Rollback
      end
    end
  end
  
  desc "Import Product Prices from Excel"
  task product_prices: :environment do
    workbook = Creek::Book.new Rails.root.join("public", "import price list table format.xlsx").to_s
    worksheets = workbook.sheets

    error_row = ""
    ActiveRecord::Base.transaction do
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
                puts price_list.errors.inspect
                error_row = "invalid index => #{idx}"
                break
              end
            rescue Exception => e
              puts e.inspect
              error_row = "invalid index => #{idx}, product_detail_id => #{product_detail_id}, product_id => #{product_id}, cost => #{cost}"
              break
            end
          end
        end
        break if error_row.present?
      end
      if error_row.present?
        puts error_row
        raise ActiveRecord::Rollback
      end
    end
  end  
  
  desc "Import Product Prices bag.2 from Excel"
  task product_prices_part_2: :environment do
    workbook = Creek::Book.new Rails.root.join("public", "daftar price yang di skip.xlsx").to_s
    worksheets = workbook.sheets

    error_row = ""
    ActiveRecord::Base.transaction do
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
                puts price_list.errors.inspect
                error_row = "invalid index => #{idx}"
                break
              end
            rescue Exception => e
              puts e.inspect
              error_row = "invalid index => #{idx}, product_detail_id => #{product_detail_id}, product_id => #{product_id}, cost => #{cost}"
              break
            end
          end
        end
        break if error_row.present?
      end
      if error_row.present?
        puts error_row
        raise ActiveRecord::Rollback
      end
    end
  end  
  
  desc "Import Product Colors from Excel"
  task product_colors: :environment do
    workbook = Creek::Book.new Rails.root.join("public", "import product color table format.xlsx").to_s
    worksheets = workbook.sheets

    error_row = ""
    ActiveRecord::Base.transaction do
      worksheets.each do |worksheet|
        worksheet.rows.each_with_index do |row, idx|
          product_id = 0
          color_id = 0
          if row.present? && idx > 1
            begin
              product_id = Product.select(:id).where(code: row["A#{idx + 1}"]).first.id
              color_id = Color.select(:id).where(code: row["B#{idx + 1}"]).first.id
              product_color = ProductColor.new product_id: product_id, color_id: color_id
              product_color.attr_importing_data = true
              unless product_color.save
                puts product_color.errors.inspect
                error_row = "invalid index => #{idx}"
                break
              end
            rescue Exception => e
              puts e.inspect
              error_row = "invalid index => #{idx}, product_id => #{product_id}, color_id => #{color_id}"
              break
            end
          end
        end
        break if error_row.present?
      end
      if error_row.present?
        puts error_row
        raise ActiveRecord::Rollback
      end
    end
  end  
  
  desc "Import Product Barcode from Excel"
  task product_barcodes: :environment do
    workbook = Creek::Book.new Rails.root.join("public", "import product barcode table format.xlsx").to_s
    worksheets = workbook.sheets

    error_row = ""
    ActiveRecord::Base.transaction do
      worksheets.each do |worksheet|
        worksheet.rows.each_with_index do |row, idx|
          product_color_id = 0
          size_group_id = 0
          size_id = 0
          if row.present? && idx > 1
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
                puts product_barcode.errors.inspect
                error_row = "invalid index => #{idx}"
                break
              end
            rescue Exception => e
              puts e.inspect
              error_row = "invalid index => #{idx}, product_color_id => #{product_color_id}, size_group_id => #{size_group_id}, size_id => #{size_id}"
              break
            end
          end
        end
        break if error_row.present?
      end
      if error_row.present?
        puts error_row
        raise ActiveRecord::Rollback
      end
    end
  end  
end
