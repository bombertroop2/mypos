# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151231133740) do

  create_table "common_fields", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.string   "type"
    t.string   "code"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "product_detail_histories", force: :cascade do |t|
    t.decimal  "cost"
    t.decimal  "price"
    t.integer  "product_detail_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "product_detail_histories", ["product_detail_id"], name: "index_product_detail_histories_on_product_detail_id"

  create_table "product_details", force: :cascade do |t|
    t.integer  "product_id"
    t.integer  "size_id"
    t.decimal  "cost",          precision: 12, scale: 2
    t.decimal  "price",         precision: 12, scale: 2
    t.string   "barcode"
    t.integer  "color_id"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.integer  "price_code_id"
  end

  add_index "product_details", ["color_id"], name: "index_product_details_on_color_id"
  add_index "product_details", ["price_code_id"], name: "index_product_details_on_price_code_id"
  add_index "product_details", ["product_id"], name: "index_product_details_on_product_id"
  add_index "product_details", ["size_id"], name: "index_product_details_on_size_id"

  create_table "products", force: :cascade do |t|
    t.string   "code"
    t.text     "description"
    t.integer  "brand_id"
    t.string   "sex"
    t.integer  "vendor_id"
    t.string   "target"
    t.integer  "model_id"
    t.integer  "goods_type_id"
    t.string   "image"
    t.date     "effective_date"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "products", ["brand_id"], name: "index_products_on_brand_id"
  add_index "products", ["goods_type_id"], name: "index_products_on_goods_type_id"
  add_index "products", ["model_id"], name: "index_products_on_model_id"
  add_index "products", ["vendor_id"], name: "index_products_on_vendor_id"

  create_table "purchase_orders", force: :cascade do |t|
    t.string   "number"
    t.string   "po_type"
    t.string   "status"
    t.integer  "vendor_id"
    t.date     "request_delivery_date"
    t.decimal  "order_value"
    t.decimal  "receiving_value"
    t.integer  "means_of_payment"
    t.integer  "warehouse_id"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "purchase_orders", ["vendor_id"], name: "index_purchase_orders_on_vendor_id"
  add_index "purchase_orders", ["warehouse_id"], name: "index_purchase_orders_on_warehouse_id"

  create_table "sales_promotion_girls", force: :cascade do |t|
    t.string   "identifier"
    t.string   "name"
    t.text     "address"
    t.string   "phone"
    t.string   "province"
    t.integer  "warehouse_id"
    t.string   "mobile_phone"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "sales_promotion_girls", ["warehouse_id"], name: "index_sales_promotion_girls_on_warehouse_id"

  create_table "size_groups", force: :cascade do |t|
    t.string   "code"
    t.text     "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "sizes", force: :cascade do |t|
    t.integer  "size_group_id"
    t.string   "size"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "sizes", ["size_group_id"], name: "index_sizes_on_size_group_id"

  create_table "supervisors", force: :cascade do |t|
    t.string   "code"
    t.string   "name"
    t.text     "address"
    t.string   "email"
    t.string   "phone"
    t.string   "mobile_phone"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "vendors", force: :cascade do |t|
    t.string   "code"
    t.string   "name"
    t.string   "phone"
    t.string   "facsimile"
    t.string   "email"
    t.string   "pic_name"
    t.string   "pic_phone"
    t.string   "pic_mobile_phone"
    t.string   "pic_email"
    t.text     "address"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "warehouses", force: :cascade do |t|
    t.string   "code"
    t.string   "name"
    t.text     "address"
    t.boolean  "is_active"
    t.integer  "supervisor_id"
    t.integer  "region_id"
    t.string   "warehouse_type"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "price_code_id"
  end

  add_index "warehouses", ["price_code_id"], name: "index_warehouses_on_price_code_id"
  add_index "warehouses", ["region_id"], name: "index_warehouses_on_region_id"
  add_index "warehouses", ["supervisor_id"], name: "index_warehouses_on_supervisor_id"

end
