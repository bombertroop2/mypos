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
end
