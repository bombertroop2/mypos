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

ActiveRecord::Schema.define(version: 20160312005511) do

  create_table "common_fields", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.string   "type"
    t.string   "code"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "common_fields", ["code", "type"], name: "index_common_fields_on_code_and_type", unique: true

  create_table "product_detail_histories", force: :cascade do |t|
    t.decimal  "price"
    t.integer  "product_detail_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "product_detail_histories", ["product_detail_id"], name: "index_product_detail_histories_on_product_detail_id"

  create_table "product_details", force: :cascade do |t|
    t.integer  "size_id"
    t.decimal  "price"
    t.string   "barcode"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "product_id"
    t.integer  "price_code_id"
  end

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
    t.decimal  "cost"
    t.integer  "size_group_id"
  end

  add_index "products", ["brand_id"], name: "index_products_on_brand_id"
  add_index "products", ["code"], name: "index_products_on_code", unique: true
  add_index "products", ["goods_type_id"], name: "index_products_on_goods_type_id"
  add_index "products", ["model_id"], name: "index_products_on_model_id"
  add_index "products", ["size_group_id"], name: "index_products_on_size_group_id"
  add_index "products", ["vendor_id"], name: "index_products_on_vendor_id"

  create_table "purchase_order_details", force: :cascade do |t|
    t.integer  "quantity"
    t.decimal  "total_unit_price"
    t.integer  "receiving_qty"
    t.date     "delivery_date"
    t.integer  "purchase_order_product_id"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "size_id"
    t.integer  "color_id"
  end

  add_index "purchase_order_details", ["color_id"], name: "index_purchase_order_details_on_color_id"
  add_index "purchase_order_details", ["purchase_order_product_id"], name: "index_purchase_order_details_on_purchase_order_product_id"
  add_index "purchase_order_details", ["size_id"], name: "index_purchase_order_details_on_size_id"

  create_table "purchase_order_products", force: :cascade do |t|
    t.integer  "purchase_order_id"
    t.integer  "product_id"
    t.integer  "warehouse_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "purchase_order_products", ["product_id"], name: "index_purchase_order_products_on_product_id"
  add_index "purchase_order_products", ["purchase_order_id"], name: "index_purchase_order_products_on_purchase_order_id"
  add_index "purchase_order_products", ["warehouse_id"], name: "index_purchase_order_products_on_warehouse_id"

  create_table "purchase_orders", force: :cascade do |t|
    t.string   "number"
    t.string   "po_type"
    t.string   "status"
    t.integer  "vendor_id"
    t.date     "request_delivery_date"
    t.decimal  "order_value"
    t.decimal  "receiving_value"
    t.integer  "warehouse_id"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "purchase_orders", ["number"], name: "index_purchase_orders_on_number", unique: true
  add_index "purchase_orders", ["vendor_id"], name: "index_purchase_orders_on_vendor_id"
  add_index "purchase_orders", ["warehouse_id"], name: "index_purchase_orders_on_warehouse_id"

  create_table "purchase_return_items", force: :cascade do |t|
    t.integer  "purchase_return_product_id"
    t.integer  "quantity"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "purchase_order_detail_id"
  end

  add_index "purchase_return_items", ["purchase_order_detail_id"], name: "index_purchase_return_items_on_purchase_order_detail_id"
  add_index "purchase_return_items", ["purchase_return_product_id"], name: "index_purchase_return_items_on_purchase_return_product_id"

  create_table "purchase_return_products", force: :cascade do |t|
    t.integer  "purchase_return_id"
    t.integer  "total_quantity"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "purchase_order_product_id"
  end

  add_index "purchase_return_products", ["purchase_order_product_id"], name: "index_purchase_return_products_on_purchase_order_product_id"
  add_index "purchase_return_products", ["purchase_return_id"], name: "index_purchase_return_products_on_purchase_return_id"

  create_table "purchase_returns", force: :cascade do |t|
    t.string   "number"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "purchase_order_id"
  end

  add_index "purchase_returns", ["purchase_order_id"], name: "index_purchase_returns_on_purchase_order_id"

  create_table "received_purchase_orders", force: :cascade do |t|
    t.integer  "purchase_order_product_id"
    t.integer  "color_id"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "received_purchase_orders", ["color_id"], name: "index_received_purchase_orders_on_color_id"
  add_index "received_purchase_orders", ["purchase_order_product_id"], name: "index_received_purchase_orders_on_purchase_order_product_id"

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
  add_index "roles", ["name"], name: "index_roles_on_name"

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
    t.string   "gender"
    t.string   "role"
  end

  add_index "sales_promotion_girls", ["identifier"], name: "index_sales_promotion_girls_on_identifier", unique: true
  add_index "sales_promotion_girls", ["warehouse_id"], name: "index_sales_promotion_girls_on_warehouse_id"

  create_table "size_groups", force: :cascade do |t|
    t.string   "code"
    t.text     "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "size_groups", ["code"], name: "index_size_groups_on_code", unique: true

  create_table "sizes", force: :cascade do |t|
    t.integer  "size_group_id"
    t.string   "size"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "sizes", ["size_group_id"], name: "index_sizes_on_size_group_id"

  create_table "stocks", force: :cascade do |t|
    t.integer  "purchase_order_detail_id"
    t.string   "stock_type"
    t.integer  "quantity_on_hand"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "stocks", ["purchase_order_detail_id"], name: "index_stocks_on_purchase_order_detail_id"

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

  add_index "supervisors", ["code"], name: "index_supervisors_on_code", unique: true
  add_index "supervisors", ["email"], name: "index_supervisors_on_email", unique: true

  create_table "users", force: :cascade do |t|
    t.string   "email",                   default: "", null: false
    t.string   "encrypted_password",      default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",           default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "sales_promotion_girl_id"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  add_index "users", ["sales_promotion_girl_id"], name: "index_users_on_sales_promotion_girl_id"

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"

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
    t.integer  "terms_of_payment"
    t.string   "value_added_tax"
  end

  add_index "vendors", ["code"], name: "index_vendors_on_code", unique: true

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

  add_index "warehouses", ["code"], name: "index_warehouses_on_code", unique: true
  add_index "warehouses", ["price_code_id"], name: "index_warehouses_on_price_code_id"
  add_index "warehouses", ["region_id"], name: "index_warehouses_on_region_id"
  add_index "warehouses", ["supervisor_id"], name: "index_warehouses_on_supervisor_id"

end
