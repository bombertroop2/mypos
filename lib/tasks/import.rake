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
end
