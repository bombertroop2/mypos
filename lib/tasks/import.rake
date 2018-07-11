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

  desc "Import Products from Excel"
  task products: :environment do 
    workbook = Creek::Book.new Rails.root.join("public", "import product table format.xlsx").to_s
    worksheets = workbook.sheets

    error_row = ""
    ActiveRecord::Base.transaction do
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
              sex = Product::SEX.select{ |x| x[1] == row["C#{idx + 1}"].strip.downcase }.first.first.downcase
              vendor_id = Vendor.select(:id).where(code: row["D#{idx + 1}"].strip).first.id
              target = Product::TARGETS.select{ |x| x[1] == row["E#{idx + 1}"].strip.downcase }.first.first.downcase
              model_id = Model.select(:id).where(code: row["F#{idx + 1}"].strip).first.id
              goods_type_id = GoodsType.select(:id).where(code: row["G#{idx + 1}"].strip).first.id
              size_group_id = SizeGroup.select(:id).where(code: row["H#{idx + 1}"].strip).first.id
              product = Product.new code: row["A#{idx + 1}"].strip, brand_id: brand_id, sex: sex, vendor_id: vendor_id, target: target, model_id: model_id, goods_type_id: goods_type_id, size_group_id: size_group_id, additional_information: (row["I#{idx + 1}"].present? ? row["I#{idx + 1}"].strip : nil)
              product.attr_importing_data = true
              unless product.save
                puts product.errors.inspect
                error_row = "invalid index => #{idx}"
                break
              end
            rescue Exception => e
              puts e.inspect
              error_row = "invalid index => #{idx}, brand id => #{brand_id}, sex => #{sex}, vendor_id => #{vendor_id}, target => #{target}, model_id => #{model_id}, goods_type_id => #{goods_type_id}, size_group_id => #{size_group_id}"
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
