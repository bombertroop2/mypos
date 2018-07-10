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

    worksheets.each do |worksheet|
      worksheet.rows.each_with_index do |row, idx|
        if row.present? && idx > 1
          model = Model.new code: row["A#{idx + 1}"], name: row["B#{idx + 1}"], type: row["C#{idx + 1}"], description: row["D#{idx + 1}"]
          model.save
        end
      end
    end
  end
end
