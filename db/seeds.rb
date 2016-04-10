# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


if User.with_any_role(:admin).blank?
  user = User.create email: "rizkinoorlaksana@gmail.com", password: "admin123"
  user.add_role :admin
end

if Brand.count < 1
  Brand.create name: "Adidas", code: "AD"
  Brand.create name: "Nike", code: "NK"
  Brand.create name: "Puma", code: "PM"
end

if Color.count < 1
  Color.create name: "White/Black", code: "WHB"
end

if Model.count < 1
  Model.create name: "Running", code: "RNL"
  Model.create name: "Footwear", code: "FTW"
  Model.create name: "Apparel", code: "APR"
end

if GoodsType.count < 1
  GoodsType.create name: "Not Available", code: "NA"
end

if Region.count < 1
  Region.create name: "Jabodetabek", code: "JBK"
end

if PriceCode.count < 1
  PriceCode.create name: "Price Jakarta", code: "JKT"
  PriceCode.create name: "Price Luar Jakarta", code: "NJK"
end

if Vendor.count < 1
  Vendor.create name: "Delami", code: "DLM01", address: "Jakarta", terms_of_payment: 90, value_added_tax: "Exclude"
end

if SizeGroup.count < 1
  SizeGroup.create code: "A"
end

if Size.count < 1
  size_group = SizeGroup.first
  Size.create size: "6", size_group_id: size_group.id
  Size.create size: "6-", size_group_id: size_group.id
  Size.create size: "7", size_group_id: size_group.id
  Size.create size: "7-", size_group_id: size_group.id
  Size.create size: "8", size_group_id: size_group.id
end

if Supervisor.count < 1
  Supervisor.create code: "ACN", name: "Acien", address: "Jakarta", email: "acien@gmail.com"
end

if Warehouse.count < 1
  Warehouse.create code: "GDP", name: "Gudang Pusat", address: "Jakarta", is_active: true, supervisor_id: Supervisor.first.id, region_id: Region.first.id, price_code_id: PriceCode.first.id, warehouse_type: "central"
end
