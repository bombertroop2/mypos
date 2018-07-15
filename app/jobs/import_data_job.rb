class ImportDataJob < ApplicationJob
  queue_as :default

  def perform(type)
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
    end
  end
end
