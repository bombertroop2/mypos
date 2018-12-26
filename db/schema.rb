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

ActiveRecord::Schema.define(version: 20181226030428) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "account_payable_purchases", force: :cascade do |t|
    t.integer  "purchase_id"
    t.string   "purchase_type",      limit: 20
    t.integer  "account_payable_id"
    t.datetime "created_at",                    precision: 6, null: false
    t.datetime "updated_at",                    precision: 6, null: false
    t.index ["account_payable_id"], name: "index_account_payable_purchases_on_account_payable_id", using: :btree
    t.index ["purchase_id", "purchase_type", "account_payable_id"], name: "index_app_on_purchase_id_purchase_type_account_payable_id", unique: true, using: :btree
  end

  create_table "account_payables", force: :cascade do |t|
    t.string   "number"
    t.string   "payment_method"
    t.decimal  "amount_paid"
    t.decimal  "amount_returned"
    t.string   "giro_number"
    t.date     "giro_date"
    t.date     "payment_date"
    t.integer  "vendor_id"
    t.datetime "created_at",      precision: 6, null: false
    t.datetime "updated_at",      precision: 6, null: false
    t.text     "note"
    t.index ["number"], name: "index_account_payables_on_number", unique: true, using: :btree
    t.index ["vendor_id"], name: "index_account_payables_on_vendor_id", using: :btree
  end

  create_table "accounting_account_categories", force: :cascade do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.integer  "classification"
    t.datetime "created_at",     precision: 6, null: false
    t.datetime "updated_at",     precision: 6, null: false
  end

  create_table "accounting_account_saldos", force: :cascade do |t|
    t.integer  "coa_id"
    t.float    "saldo"
    t.string   "year"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "accounting_account_settings", force: :cascade do |t|
    t.integer  "coa_id"
    t.string   "type"
    t.boolean  "is_debit"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "accounting_accounts", force: :cascade do |t|
    t.string   "code"
    t.string   "description"
    t.integer  "classification"
    t.integer  "category_id"
    t.integer  "parent_id"
    t.datetime "created_at",     precision: 6, null: false
    t.datetime "updated_at",     precision: 6, null: false
  end

  create_table "accounting_jurnal_transction_details", force: :cascade do |t|
    t.integer  "transction_id"
    t.integer  "coa_id"
    t.boolean  "is_debit"
    t.decimal  "total",         precision: 10, scale: 2
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  create_table "accounting_jurnal_transctions", force: :cascade do |t|
    t.string   "type_jurnal"
    t.string   "description"
    t.integer  "model_id"
    t.string   "model_type"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "warehouse_id"
  end

  create_table "adjustment_product_details", force: :cascade do |t|
    t.integer  "adjustment_product_id"
    t.integer  "quantity",                            default: 0
    t.integer  "color_id"
    t.integer  "size_id"
    t.datetime "created_at",            precision: 6,             null: false
    t.datetime "updated_at",            precision: 6,             null: false
    t.index ["adjustment_product_id", "color_id", "size_id"], name: "index_apd_on_adjustment_product_id_and_color_id_and_size_id", unique: true, using: :btree
    t.index ["color_id"], name: "index_adjustment_product_details_on_color_id", using: :btree
    t.index ["size_id"], name: "index_adjustment_product_details_on_size_id", using: :btree
  end

  create_table "adjustment_products", force: :cascade do |t|
    t.integer  "adjustment_id"
    t.integer  "product_id"
    t.integer  "quantity",                    default: 0
    t.datetime "created_at",    precision: 6,             null: false
    t.datetime "updated_at",    precision: 6,             null: false
    t.index ["adjustment_id", "product_id"], name: "index_adjustment_products_on_adjustment_id_and_product_id", unique: true, using: :btree
    t.index ["product_id"], name: "index_adjustment_products_on_product_id", using: :btree
  end

  create_table "adjustments", force: :cascade do |t|
    t.integer  "warehouse_id"
    t.string   "adj_type"
    t.date     "adj_date"
    t.integer  "quantity",                   default: 0
    t.datetime "created_at",   precision: 6,             null: false
    t.datetime "updated_at",   precision: 6,             null: false
    t.string   "number"
    t.index ["warehouse_id"], name: "index_adjustments_on_warehouse_id", using: :btree
  end

  create_table "allocated_return_items", force: :cascade do |t|
    t.integer  "account_payable_id"
    t.integer  "purchase_return_id"
    t.datetime "created_at",         precision: 6, null: false
    t.datetime "updated_at",         precision: 6, null: false
    t.index ["account_payable_id", "purchase_return_id"], name: "index_ari_on_account_payable_id_and_purchase_return_id", unique: true, using: :btree
    t.index ["purchase_return_id"], name: "index_allocated_return_items_on_purchase_return_id", using: :btree
  end

  create_table "audits", force: :cascade do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "associated_id"
    t.string   "associated_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "username"
    t.string   "action"
    t.text     "audited_changes"
    t.integer  "version",                       default: 0
    t.string   "comment"
    t.string   "remote_address"
    t.string   "request_uuid"
    t.datetime "created_at",      precision: 6
    t.index ["associated_id", "associated_type"], name: "associated_index", using: :btree
    t.index ["auditable_id", "auditable_type"], name: "auditable_index", using: :btree
    t.index ["created_at"], name: "index_audits_on_created_at", using: :btree
    t.index ["request_uuid"], name: "index_audits_on_request_uuid", using: :btree
    t.index ["user_id", "user_type"], name: "user_index", using: :btree
  end

  create_table "available_menus", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean  "active"
    t.index ["active", "name"], name: "index_available_menus_on_active_and_name", using: :btree
  end

  create_table "banks", force: :cascade do |t|
    t.string   "code"
    t.string   "name"
    t.string   "card_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["code", "card_type"], name: "index_banks_on_code_and_card_type", unique: true, using: :btree
  end

  create_table "beginning_stock_products", force: :cascade do |t|
    t.integer  "product_id"
    t.datetime "created_at",   precision: 6,             null: false
    t.datetime "updated_at",   precision: 6,             null: false
    t.integer  "quantity",                   default: 0
    t.date     "import_date"
    t.integer  "warehouse_id"
    t.integer  "size_id"
    t.integer  "color_id"
    t.index ["color_id"], name: "index_beginning_stock_products_on_color_id", using: :btree
    t.index ["product_id"], name: "index_beginning_stock_products_on_product_id", using: :btree
    t.index ["size_id"], name: "index_beginning_stock_products_on_size_id", using: :btree
    t.index ["warehouse_id", "product_id", "color_id", "size_id"], name: "index_bsp_on_warehouse_id_product_id_color_id_size_id", unique: true, using: :btree
    t.index ["warehouse_id"], name: "index_beginning_stock_products_on_warehouse_id", using: :btree
  end

  create_table "cash_disbursements", force: :cascade do |t|
    t.integer  "cashier_opening_id"
    t.string   "description"
    t.decimal  "price"
    t.datetime "created_at",         precision: 6, null: false
    t.datetime "updated_at",         precision: 6, null: false
    t.index ["cashier_opening_id"], name: "index_cash_disbursements_on_cashier_opening_id", using: :btree
  end

  create_table "cashier_openings", force: :cascade do |t|
    t.integer  "warehouse_id"
    t.string   "station",             limit: 1
    t.decimal  "beginning_cash"
    t.datetime "created_at",                    precision: 6, null: false
    t.datetime "updated_at",                    precision: 6, null: false
    t.integer  "opened_by"
    t.date     "open_date"
    t.string   "shift",               limit: 1
    t.datetime "closed_at",                     precision: 6
    t.decimal  "cash_balance"
    t.decimal  "net_sales"
    t.decimal  "gross_sales"
    t.decimal  "cash_payment"
    t.decimal  "card_payment"
    t.decimal  "debit_card_payment"
    t.decimal  "credit_card_payment"
    t.integer  "total_quantity"
    t.integer  "total_gift_quantity"
    t.index ["opened_by"], name: "index_cashier_openings_on_opened_by", using: :btree
    t.index ["warehouse_id", "opened_by", "open_date"], name: "index_cashier_openings_on_warehouse_id_opened_by_open_date", unique: true, using: :btree
    t.index ["warehouse_id", "station", "shift", "open_date"], name: "idx_cashier_openings_on_warehouse_id_station_shift_open_date", unique: true, using: :btree
    t.index ["warehouse_id"], name: "index_cashier_openings_on_warehouse_id", using: :btree
  end

  create_table "cities", force: :cascade do |t|
    t.string "province_id"
    t.string "name"
  end

  create_table "coa_cashes", force: :cascade do |t|
    t.integer  "coa_id"
    t.date     "date"
    t.integer  "value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["coa_id"], name: "index_coa_cashes_on_coa_id", using: :btree
    t.index ["date", "coa_id"], name: "index_coa_cashes_on_date_and_coa_id", unique: true, using: :btree
  end

  create_table "coa_departments", force: :cascade do |t|
    t.integer  "department_id"
    t.integer  "coa_id"
    t.integer  "warehouse_id"
    t.string   "location"
    t.datetime "created_at",    precision: 6, null: false
    t.datetime "updated_at",    precision: 6, null: false
    t.index ["coa_id"], name: "index_coa_departments_on_coa_id", using: :btree
    t.index ["department_id", "coa_id", "warehouse_id"], name: "coa_department_retation_index", unique: true, using: :btree
    t.index ["department_id"], name: "index_coa_departments_on_department_id", using: :btree
    t.index ["warehouse_id"], name: "index_coa_departments_on_warehouse_id", using: :btree
  end

  create_table "coa_types", force: :cascade do |t|
    t.string   "code"
    t.string   "name"
    t.datetime "created_at",  precision: 6, null: false
    t.datetime "updated_at",  precision: 6, null: false
    t.text     "description"
    t.index ["code"], name: "index_coa_types_on_code", unique: true, using: :btree
  end

  create_table "coas", force: :cascade do |t|
    t.string   "code"
    t.string   "name"
    t.string   "transaction_type"
    t.text     "description"
    t.datetime "created_at",       precision: 6, null: false
    t.datetime "updated_at",       precision: 6, null: false
    t.string   "group"
    t.integer  "coa_type_id"
    t.index ["coa_type_id"], name: "index_coas_on_coa_type_id", using: :btree
    t.index ["code"], name: "index_coas_on_code", unique: true, using: :btree
    t.index ["transaction_type"], name: "index_coas_on_transaction_type", unique: true, using: :btree
  end

  create_table "common_fields", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.string   "type"
    t.string   "code"
    t.datetime "created_at",  precision: 6, null: false
    t.datetime "updated_at",  precision: 6, null: false
    t.index ["code", "type"], name: "index_common_fields_on_code_and_type", unique: true, using: :btree
  end

  create_table "companies", force: :cascade do |t|
    t.string   "code"
    t.string   "name"
    t.string   "taxpayer_registration_number"
    t.text     "address"
    t.string   "phone"
    t.string   "fax"
    t.integer  "total_showroom"
    t.integer  "total_counter"
    t.datetime "created_at",                   precision: 6,                null: false
    t.datetime "updated_at",                   precision: 6,                null: false
    t.boolean  "import_beginning_stock",                     default: true
  end

  create_table "consignment_sale_products", force: :cascade do |t|
    t.integer  "consignment_sale_id"
    t.integer  "product_barcode_id"
    t.integer  "price_list_id"
    t.decimal  "total"
    t.datetime "created_at",             precision: 6, null: false
    t.datetime "updated_at",             precision: 6, null: false
    t.decimal  "imported_special_price"
    t.index ["consignment_sale_id"], name: "index_consignment_sale_products_on_consignment_sale_id", using: :btree
    t.index ["price_list_id"], name: "index_consignment_sale_products_on_price_list_id", using: :btree
    t.index ["product_barcode_id"], name: "index_consignment_sale_products_on_product_barcode_id", using: :btree
  end

  create_table "consignment_sales", force: :cascade do |t|
    t.date     "transaction_date"
    t.boolean  "approved",                         default: false
    t.string   "transaction_number"
    t.decimal  "total"
    t.datetime "created_at",         precision: 6,                 null: false
    t.datetime "updated_at",         precision: 6,                 null: false
    t.integer  "warehouse_id"
    t.integer  "counter_event_id"
    t.boolean  "no_sale",                          default: false
    t.index ["counter_event_id"], name: "index_consignment_sales_on_counter_event_id", using: :btree
    t.index ["transaction_number"], name: "index_consignment_sales_on_transaction_number", unique: true, using: :btree
    t.index ["warehouse_id", "transaction_date"], name: "index_consignment_sales_on_warehouse_id_and_transaction_date", using: :btree
  end

  create_table "cost_lists", force: :cascade do |t|
    t.date     "effective_date"
    t.decimal  "cost"
    t.integer  "product_id"
    t.datetime "created_at",     precision: 6, null: false
    t.datetime "updated_at",     precision: 6, null: false
    t.index ["product_id", "effective_date"], name: "index_cost_lists_on_product_id_and_effective_date", unique: true, using: :btree
  end

  create_table "counter_event_general_products", force: :cascade do |t|
    t.integer  "counter_event_id"
    t.integer  "product_id"
    t.datetime "created_at",       precision: 6, null: false
    t.datetime "updated_at",       precision: 6, null: false
  end

  create_table "counter_event_warehouses", force: :cascade do |t|
    t.integer  "counter_event_id"
    t.integer  "warehouse_id"
    t.boolean  "is_active",                      default: false
    t.datetime "created_at",       precision: 6,                 null: false
    t.datetime "updated_at",       precision: 6,                 null: false
    t.index ["counter_event_id", "warehouse_id"], name: "index_cew_on_counter_event_id_and_warehouse_id", unique: true, using: :btree
  end

  create_table "counter_events", force: :cascade do |t|
    t.string   "code"
    t.string   "name"
    t.datetime "start_time",         precision: 6
    t.datetime "end_time",           precision: 6
    t.float    "first_discount"
    t.float    "second_discount"
    t.decimal  "special_price"
    t.float    "margin"
    t.float    "participation"
    t.datetime "created_at",         precision: 6,                null: false
    t.datetime "updated_at",         precision: 6,                null: false
    t.string   "counter_event_type"
    t.boolean  "is_active",                        default: true
  end

  create_table "courier_prices", force: :cascade do |t|
    t.integer  "courier_id"
    t.integer  "city_id"
    t.date     "effective_date"
    t.decimal  "price"
    t.string   "price_type"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["city_id"], name: "index_courier_prices_on_city_id", using: :btree
    t.index ["courier_id", "city_id", "effective_date", "price_type"], name: "index_cp_on_courier_id_n_city_id_n_effective_date_n_price_type", unique: true, using: :btree
  end

  create_table "couriers", force: :cascade do |t|
    t.string   "code"
    t.string   "name"
    t.string   "via",        limit: 4
    t.string   "unit",       limit: 8
    t.datetime "created_at",           precision: 6, null: false
    t.datetime "updated_at",           precision: 6, null: false
    t.string   "status"
  end

  create_table "customers", force: :cascade do |t|
    t.string   "code"
    t.string   "name"
    t.string   "phone"
    t.string   "facsimile"
    t.string   "email"
    t.string   "pic_name"
    t.string   "pic_mobile_phone"
    t.string   "pic_email"
    t.text     "address"
    t.integer  "terms_of_payment"
    t.boolean  "is_taxable_entrepreneur",               default: true
    t.string   "value_added_tax"
    t.decimal  "limit_value"
    t.text     "deliver_to"
    t.datetime "created_at",              precision: 6,                null: false
    t.datetime "updated_at",              precision: 6,                null: false
    t.index ["code"], name: "index_customers_on_code", unique: true, using: :btree
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",                 default: 0, null: false
    t.integer  "attempts",                 default: 0, null: false
    t.text     "handler",                              null: false
    t.text     "last_error"
    t.datetime "run_at",     precision: 6
    t.datetime "locked_at",  precision: 6
    t.datetime "failed_at",  precision: 6
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree
  end

  create_table "departments", force: :cascade do |t|
    t.string   "code"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",  precision: 6, null: false
    t.datetime "updated_at",  precision: 6, null: false
    t.index ["code"], name: "index_departments_on_code", unique: true, using: :btree
  end

  create_table "direct_purchase_details", force: :cascade do |t|
    t.integer  "quantity"
    t.decimal  "total_unit_price"
    t.integer  "direct_purchase_product_id"
    t.integer  "size_id"
    t.integer  "color_id"
    t.integer  "returning_qty"
    t.datetime "created_at",                 precision: 6, null: false
    t.datetime "updated_at",                 precision: 6, null: false
    t.index ["color_id"], name: "index_direct_purchase_details_on_color_id", using: :btree
    t.index ["direct_purchase_product_id", "size_id", "color_id"], name: "index_dpd_on_dpp_id_and_size_id_and_color_id", unique: true, using: :btree
    t.index ["size_id"], name: "index_direct_purchase_details_on_size_id", using: :btree
  end

  create_table "direct_purchase_products", force: :cascade do |t|
    t.integer  "direct_purchase_id"
    t.integer  "product_id"
    t.datetime "created_at",         precision: 6, null: false
    t.datetime "updated_at",         precision: 6, null: false
    t.integer  "cost_list_id"
    t.index ["cost_list_id"], name: "index_direct_purchase_products_on_cost_list_id", using: :btree
    t.index ["direct_purchase_id", "product_id"], name: "index_dpp_on_direct_purchase_id_and_product_id", unique: true, using: :btree
    t.index ["product_id"], name: "index_direct_purchase_products_on_product_id", using: :btree
  end

  create_table "direct_purchases", force: :cascade do |t|
    t.integer  "vendor_id"
    t.integer  "warehouse_id"
    t.float    "first_discount"
    t.float    "second_discount"
    t.boolean  "is_additional_disc_from_net"
    t.string   "vat_type"
    t.boolean  "is_taxable_entrepreneur"
    t.datetime "created_at",                  precision: 6,              null: false
    t.datetime "updated_at",                  precision: 6,              null: false
    t.date     "receiving_date"
    t.string   "invoice_status",                            default: ""
    t.index ["vendor_id"], name: "index_direct_purchases_on_vendor_id", using: :btree
    t.index ["warehouse_id"], name: "index_direct_purchases_on_warehouse_id", using: :btree
  end

  create_table "emails", force: :cascade do |t|
    t.string   "address"
    t.string   "email_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "event_general_products", force: :cascade do |t|
    t.integer  "event_id"
    t.integer  "product_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["event_id", "product_id"], name: "index_event_general_products_on_event_id_and_product_id", unique: true, using: :btree
    t.index ["event_id"], name: "index_event_general_products_on_event_id", using: :btree
    t.index ["product_id"], name: "index_event_general_products_on_product_id", using: :btree
  end

  create_table "event_products", force: :cascade do |t|
    t.integer  "event_warehouse_id"
    t.integer  "product_id"
    t.datetime "created_at",         precision: 6, null: false
    t.datetime "updated_at",         precision: 6, null: false
    t.index ["event_warehouse_id", "product_id"], name: "index_event_products_on_event_warehouse_id_and_product_id", unique: true, using: :btree
    t.index ["event_warehouse_id"], name: "index_event_products_on_event_warehouse_id", using: :btree
    t.index ["product_id"], name: "index_event_products_on_product_id", using: :btree
  end

  create_table "event_warehouses", force: :cascade do |t|
    t.integer  "event_id"
    t.integer  "warehouse_id"
    t.datetime "created_at",                precision: 6, null: false
    t.datetime "updated_at",                precision: 6, null: false
    t.boolean  "select_different_products"
    t.boolean  "is_active"
    t.index ["event_id", "warehouse_id"], name: "index_event_warehouses_on_event_id_and_warehouse_id", unique: true, using: :btree
    t.index ["event_id"], name: "index_event_warehouses_on_event_id", using: :btree
    t.index ["warehouse_id"], name: "index_event_warehouses_on_warehouse_id", using: :btree
  end

  create_table "events", force: :cascade do |t|
    t.string   "code"
    t.string   "name"
    t.datetime "start_date_time",         precision: 6
    t.datetime "end_date_time",           precision: 6
    t.datetime "created_at",              precision: 6,                null: false
    t.datetime "updated_at",              precision: 6,                null: false
    t.float    "first_plus_discount"
    t.float    "second_plus_discount"
    t.decimal  "cash_discount"
    t.decimal  "special_price"
    t.string   "event_type"
    t.decimal  "minimum_purchase_amount"
    t.decimal  "discount_amount"
    t.boolean  "is_active",                             default: true
    t.index ["code"], name: "index_events_on_code", unique: true, using: :btree
  end

  create_table "fiscal_months", force: :cascade do |t|
    t.integer  "fiscal_year_id"
    t.string   "month"
    t.string   "status"
    t.datetime "created_at",     precision: 6, null: false
    t.datetime "updated_at",     precision: 6, null: false
    t.index ["fiscal_year_id", "month"], name: "index_fiscal_months_on_fiscal_year_id_and_month", unique: true, using: :btree
    t.index ["fiscal_year_id"], name: "index_fiscal_months_on_fiscal_year_id", using: :btree
  end

  create_table "fiscal_years", force: :cascade do |t|
    t.integer  "year"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["year"], name: "index_fiscal_years_on_year", unique: true, using: :btree
  end

  create_table "journal_detail_bogos", force: :cascade do |t|
    t.integer  "journal_id"
    t.integer  "product_id"
    t.decimal  "gross"
    t.decimal  "gross_after_discount"
    t.decimal  "discount"
    t.decimal  "ppn"
    t.decimal  "nett"
    t.datetime "created_at",           precision: 6, null: false
    t.datetime "updated_at",           precision: 6, null: false
    t.index ["journal_id"], name: "index_journal_detail_bogos_on_journal_id", using: :btree
    t.index ["product_id"], name: "index_journal_detail_bogos_on_product_id", using: :btree
  end

  create_table "journal_detail_gifts", force: :cascade do |t|
    t.integer  "journal_id"
    t.integer  "product_id"
    t.decimal  "gross"
    t.decimal  "gross_after_discount"
    t.decimal  "discount"
    t.decimal  "ppn"
    t.decimal  "nett"
    t.datetime "created_at",           precision: 6, null: false
    t.datetime "updated_at",           precision: 6, null: false
    t.index ["journal_id"], name: "index_journal_detail_gifts_on_journal_id", using: :btree
    t.index ["product_id"], name: "index_journal_detail_gifts_on_product_id", using: :btree
  end

  create_table "journal_detail_non_events", force: :cascade do |t|
    t.integer  "journal_id"
    t.integer  "product_id"
    t.decimal  "gross"
    t.decimal  "gross_after_discount"
    t.decimal  "discount"
    t.decimal  "ppn"
    t.decimal  "nett"
    t.datetime "created_at",           precision: 6, null: false
    t.datetime "updated_at",           precision: 6, null: false
    t.index ["journal_id"], name: "index_journal_detail_non_events_on_journal_id", using: :btree
    t.index ["product_id"], name: "index_journal_detail_non_events_on_product_id", using: :btree
  end

  create_table "journal_discount_details", force: :cascade do |t|
    t.integer  "journal_id"
    t.integer  "product_id"
    t.decimal  "gross"
    t.decimal  "gross_after_discount"
    t.decimal  "discount"
    t.decimal  "ppn"
    t.decimal  "nett"
    t.datetime "created_at",           precision: 6, null: false
    t.datetime "updated_at",           precision: 6, null: false
    t.index ["journal_id"], name: "index_journal_discount_details_on_journal_id", using: :btree
    t.index ["product_id"], name: "index_journal_discount_details_on_product_id", using: :btree
  end

  create_table "journals", force: :cascade do |t|
    t.integer  "coa_id"
    t.decimal  "gross"
    t.decimal  "gross_after_discount"
    t.decimal  "discount"
    t.decimal  "ppn"
    t.decimal  "nett"
    t.string   "transactionable_type"
    t.integer  "transactionable_id"
    t.datetime "created_at",                precision: 6, null: false
    t.datetime "updated_at",                precision: 6, null: false
    t.date     "transaction_date"
    t.string   "activity"
    t.integer  "warehouse_id"
    t.integer  "cost_gross_price"
    t.integer  "cost_gross_after_discount"
    t.integer  "cost_discount"
    t.integer  "cost_ppn"
    t.integer  "cost_nett"
    t.index ["coa_id"], name: "index_journals_on_coa_id", using: :btree
    t.index ["transaction_date"], name: "index_journals_on_transaction_date", using: :btree
    t.index ["transactionable_type", "transactionable_id"], name: "index_journals_on_transactionable_type_and_transactionable_id", using: :btree
    t.index ["warehouse_id"], name: "index_journals_on_warehouse_id", using: :btree
  end

  create_table "listing_stock_product_details", force: :cascade do |t|
    t.integer  "listing_stock_id"
    t.integer  "color_id"
    t.integer  "size_id"
    t.datetime "created_at",       precision: 6, null: false
    t.datetime "updated_at",       precision: 6, null: false
    t.index ["color_id"], name: "index_listing_stock_product_details_on_color_id", using: :btree
    t.index ["listing_stock_id", "color_id", "size_id"], name: "index_lspd_on_listing_stock_id_and_color_id_and_size_id", unique: true, using: :btree
    t.index ["size_id"], name: "index_listing_stock_product_details_on_size_id", using: :btree
  end

  create_table "listing_stock_transactions", force: :cascade do |t|
    t.integer  "listing_stock_product_detail_id"
    t.date     "transaction_date"
    t.string   "transaction_number"
    t.string   "transaction_type"
    t.integer  "transactionable_id"
    t.string   "transactionable_type"
    t.integer  "quantity"
    t.datetime "created_at",                      precision: 6, null: false
    t.datetime "updated_at",                      precision: 6, null: false
    t.index ["listing_stock_product_detail_id", "transaction_date"], name: "index_lst_on_lspd_id_and_transaction_date", using: :btree
    t.index ["listing_stock_product_detail_id", "transactionable_type", "transactionable_id"], name: "index_lst_on_lspd_id_transactionable_type_transactionable_id", unique: true, using: :btree
    t.index ["transaction_type"], name: "index_listing_stock_transactions_on_transaction_type", using: :btree
    t.index ["transactionable_type", "transactionable_id"], name: "index_lst_on_transactionable_type_and_transactionable_id", using: :btree
  end

  create_table "listing_stocks", force: :cascade do |t|
    t.integer  "warehouse_id"
    t.integer  "product_id"
    t.datetime "created_at",   precision: 6, null: false
    t.datetime "updated_at",   precision: 6, null: false
    t.index ["product_id"], name: "index_listing_stocks_on_product_id", using: :btree
    t.index ["warehouse_id", "product_id"], name: "index_listing_stocks_on_warehouse_id_and_product_id", unique: true, using: :btree
  end

  create_table "members", force: :cascade do |t|
    t.string   "name"
    t.string   "address"
    t.string   "phone"
    t.string   "mobile_phone"
    t.string   "gender"
    t.string   "email"
    t.datetime "created_at",   precision: 6, null: false
    t.datetime "updated_at",   precision: 6, null: false
    t.string   "member_id"
    t.index ["member_id"], name: "index_members_on_member_id", unique: true, using: :btree
  end

  create_table "notifications", force: :cascade do |t|
    t.string   "event"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string   "body"
    t.integer  "user_id"
    t.index ["user_id"], name: "index_notifications_on_user_id", using: :btree
  end

  create_table "order_booking_product_items", force: :cascade do |t|
    t.integer  "order_booking_product_id"
    t.integer  "size_id"
    t.integer  "color_id"
    t.integer  "quantity"
    t.datetime "created_at",               precision: 6, null: false
    t.datetime "updated_at",               precision: 6, null: false
    t.integer  "origin_warehouse_id"
    t.integer  "available_quantity"
    t.index ["color_id"], name: "index_order_booking_product_items_on_color_id", using: :btree
    t.index ["order_booking_product_id", "size_id", "color_id"], name: "index_obpi_on_obp_id_and_size_id_and_color_id", unique: true, using: :btree
    t.index ["size_id"], name: "index_order_booking_product_items_on_size_id", using: :btree
  end

  create_table "order_booking_products", force: :cascade do |t|
    t.integer  "order_booking_id"
    t.integer  "product_id"
    t.integer  "quantity"
    t.datetime "created_at",       precision: 6, null: false
    t.datetime "updated_at",       precision: 6, null: false
    t.index ["order_booking_id", "product_id"], name: "index_obp_on_order_booking_id_and_product_id", unique: true, using: :btree
    t.index ["product_id"], name: "index_order_booking_products_on_product_id", using: :btree
  end

  create_table "order_bookings", force: :cascade do |t|
    t.date     "plan_date"
    t.integer  "origin_warehouse_id"
    t.integer  "destination_warehouse_id"
    t.datetime "print_date",                         precision: 6
    t.text     "note"
    t.datetime "created_at",                         precision: 6, null: false
    t.datetime "updated_at",                         precision: 6, null: false
    t.integer  "quantity"
    t.string   "number"
    t.string   "status",                   limit: 1
    t.integer  "customer_id"
    t.index ["customer_id"], name: "index_order_bookings_on_customer_id", using: :btree
    t.index ["destination_warehouse_id"], name: "index_order_bookings_on_destination_warehouse_id", using: :btree
    t.index ["number"], name: "index_order_bookings_on_number", unique: true, using: :btree
    t.index ["origin_warehouse_id"], name: "index_order_bookings_on_origin_warehouse_id", using: :btree
  end

  create_table "price_lists", force: :cascade do |t|
    t.date     "effective_date"
    t.decimal  "price"
    t.integer  "product_detail_id"
    t.datetime "created_at",        precision: 6, null: false
    t.datetime "updated_at",        precision: 6, null: false
    t.index ["effective_date", "product_detail_id"], name: "index_price_lists_on_effective_date_and_product_detail_id", unique: true, using: :btree
    t.index ["product_detail_id"], name: "index_price_lists_on_product_detail_id", using: :btree
  end

  create_table "product_barcodes", force: :cascade do |t|
    t.integer  "product_color_id"
    t.integer  "size_id"
    t.string   "barcode"
    t.datetime "created_at",       precision: 6, null: false
    t.datetime "updated_at",       precision: 6, null: false
    t.index ["barcode"], name: "index_product_barcodes_on_barcode", unique: true, using: :btree
    t.index ["product_color_id", "size_id"], name: "index_product_barcodes_on_product_color_id_and_size_id", unique: true, using: :btree
    t.index ["product_color_id"], name: "index_product_barcodes_on_product_color_id", using: :btree
    t.index ["size_id"], name: "index_product_barcodes_on_size_id", using: :btree
  end

  create_table "product_colors", force: :cascade do |t|
    t.integer  "product_id"
    t.integer  "color_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["color_id"], name: "index_product_colors_on_color_id", using: :btree
    t.index ["product_id", "color_id"], name: "index_product_colors_on_product_id_and_color_id", unique: true, using: :btree
  end

  create_table "product_details", force: :cascade do |t|
    t.integer  "size_id"
    t.datetime "created_at",    precision: 6, null: false
    t.datetime "updated_at",    precision: 6, null: false
    t.integer  "product_id"
    t.integer  "price_code_id"
    t.index ["price_code_id"], name: "index_product_details_on_price_code_id", using: :btree
    t.index ["product_id"], name: "index_product_details_on_product_id", using: :btree
    t.index ["size_id", "product_id", "price_code_id"], name: "index_pd_on_size_id_and_product_id_and_price_code_id", unique: true, using: :btree
  end

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
    t.datetime "created_at",             precision: 6, null: false
    t.datetime "updated_at",             precision: 6, null: false
    t.integer  "size_group_id"
    t.string   "additional_information"
    t.index ["brand_id"], name: "index_products_on_brand_id", using: :btree
    t.index ["code"], name: "index_products_on_code", unique: true, using: :btree
    t.index ["goods_type_id"], name: "index_products_on_goods_type_id", using: :btree
    t.index ["model_id"], name: "index_products_on_model_id", using: :btree
    t.index ["size_group_id"], name: "index_products_on_size_group_id", using: :btree
    t.index ["vendor_id"], name: "index_products_on_vendor_id", using: :btree
  end

  create_table "provinces", force: :cascade do |t|
    t.string "name"
  end

  create_table "purchase_order_details", force: :cascade do |t|
    t.integer  "quantity"
    t.integer  "receiving_qty"
    t.date     "delivery_date"
    t.integer  "purchase_order_product_id"
    t.datetime "created_at",                precision: 6, null: false
    t.datetime "updated_at",                precision: 6, null: false
    t.integer  "size_id"
    t.integer  "color_id"
    t.integer  "returning_qty"
    t.index ["color_id"], name: "index_purchase_order_details_on_color_id", using: :btree
    t.index ["purchase_order_product_id", "size_id", "color_id"], name: "index_pod_on_purchase_order_product_id_size_id_color_id", unique: true, using: :btree
    t.index ["size_id"], name: "index_purchase_order_details_on_size_id", using: :btree
  end

  create_table "purchase_order_products", force: :cascade do |t|
    t.integer  "purchase_order_id"
    t.integer  "product_id"
    t.datetime "created_at",        precision: 6, null: false
    t.datetime "updated_at",        precision: 6, null: false
    t.integer  "cost_list_id"
    t.index ["cost_list_id"], name: "index_purchase_order_products_on_cost_list_id", using: :btree
    t.index ["product_id"], name: "index_purchase_order_products_on_product_id", using: :btree
    t.index ["purchase_order_id", "product_id"], name: "index_pop_on_purchase_order_id_and_product_id", unique: true, using: :btree
  end

  create_table "purchase_orders", force: :cascade do |t|
    t.string   "number"
    t.string   "po_type"
    t.string   "status"
    t.integer  "vendor_id"
    t.date     "request_delivery_date"
    t.decimal  "order_value"
    t.decimal  "receiving_value"
    t.integer  "warehouse_id"
    t.datetime "created_at",                  precision: 6,              null: false
    t.datetime "updated_at",                  precision: 6,              null: false
    t.date     "purchase_order_date"
    t.float    "first_discount"
    t.float    "second_discount"
    t.string   "value_added_tax"
    t.boolean  "is_taxable_entrepreneur"
    t.boolean  "is_additional_disc_from_net"
    t.text     "note"
    t.string   "invoice_status",                            default: ""
    t.decimal  "net_amount"
    t.index ["number"], name: "index_purchase_orders_on_number", unique: true, using: :btree
    t.index ["vendor_id"], name: "index_purchase_orders_on_vendor_id", using: :btree
    t.index ["warehouse_id"], name: "index_purchase_orders_on_warehouse_id", using: :btree
  end

  create_table "purchase_return_items", force: :cascade do |t|
    t.integer  "purchase_return_product_id"
    t.integer  "quantity"
    t.datetime "created_at",                 precision: 6, null: false
    t.datetime "updated_at",                 precision: 6, null: false
    t.integer  "purchase_order_detail_id"
    t.integer  "direct_purchase_detail_id"
    t.index ["direct_purchase_detail_id"], name: "index_purchase_return_items_on_direct_purchase_detail_id", using: :btree
    t.index ["purchase_order_detail_id"], name: "index_purchase_return_items_on_purchase_order_detail_id", using: :btree
    t.index ["purchase_return_product_id", "direct_purchase_detail_id"], name: "index_pri_on_prp_id_and_dpd_id", unique: true, using: :btree
    t.index ["purchase_return_product_id", "purchase_order_detail_id"], name: "index_pri_on_prp_id_and_pod_id", unique: true, using: :btree
  end

  create_table "purchase_return_products", force: :cascade do |t|
    t.integer  "purchase_return_id"
    t.integer  "total_quantity"
    t.datetime "created_at",                 precision: 6, null: false
    t.datetime "updated_at",                 precision: 6, null: false
    t.integer  "purchase_order_product_id"
    t.integer  "direct_purchase_product_id"
    t.index ["direct_purchase_product_id"], name: "index_purchase_return_products_on_direct_purchase_product_id", using: :btree
    t.index ["purchase_order_product_id"], name: "index_purchase_return_products_on_purchase_order_product_id", using: :btree
    t.index ["purchase_return_id", "direct_purchase_product_id"], name: "index_prp_on_purchase_return_id_and_direct_purchase_product_id", unique: true, using: :btree
    t.index ["purchase_return_id", "purchase_order_product_id"], name: "index_prp_on_purchase_return_id_and_purchase_order_product_id", unique: true, using: :btree
  end

  create_table "purchase_returns", force: :cascade do |t|
    t.string   "number"
    t.datetime "created_at",         precision: 6,                 null: false
    t.datetime "updated_at",         precision: 6,                 null: false
    t.integer  "purchase_order_id"
    t.integer  "direct_purchase_id"
    t.boolean  "is_allocated",                     default: false
    t.index ["direct_purchase_id"], name: "index_purchase_returns_on_direct_purchase_id", using: :btree
    t.index ["number"], name: "index_purchase_returns_on_number", unique: true, using: :btree
    t.index ["purchase_order_id"], name: "index_purchase_returns_on_purchase_order_id", using: :btree
  end

  create_table "received_purchase_order_items", force: :cascade do |t|
    t.integer  "received_purchase_order_product_id"
    t.integer  "quantity"
    t.datetime "created_at",                         precision: 6, null: false
    t.datetime "updated_at",                         precision: 6, null: false
    t.integer  "purchase_order_detail_id"
    t.integer  "direct_purchase_detail_id"
    t.index ["purchase_order_detail_id"], name: "received_purchase_order_detail_index", using: :btree
    t.index ["received_purchase_order_product_id", "direct_purchase_detail_id"], name: "index_rpoi_on_rpop_id_and_dpd_id", unique: true, using: :btree
    t.index ["received_purchase_order_product_id", "purchase_order_detail_id"], name: "index_rpoi_on_rpop_id_and_pod_id", unique: true, using: :btree
  end

  create_table "received_purchase_order_products", force: :cascade do |t|
    t.integer  "received_purchase_order_id"
    t.datetime "created_at",                 precision: 6, null: false
    t.datetime "updated_at",                 precision: 6, null: false
    t.integer  "purchase_order_product_id"
    t.integer  "direct_purchase_product_id"
    t.index ["direct_purchase_product_id"], name: "index_rpop_on_direct_purchase_product_id", using: :btree
    t.index ["purchase_order_product_id"], name: "received_purchase_order_product_index", using: :btree
    t.index ["received_purchase_order_id", "direct_purchase_product_id"], name: "index_rpop_on_rpo_id_and_dpp_id", unique: true, using: :btree
    t.index ["received_purchase_order_id", "purchase_order_product_id"], name: "index_rpop_on_rpo_id_and_pop_id", unique: true, using: :btree
  end

  create_table "received_purchase_orders", force: :cascade do |t|
    t.datetime "created_at",              precision: 6, null: false
    t.datetime "updated_at",              precision: 6, null: false
    t.string   "delivery_order_number"
    t.integer  "purchase_order_id"
    t.string   "is_using_delivery_order"
    t.integer  "direct_purchase_id"
    t.date     "receiving_date"
    t.integer  "vendor_id"
    t.integer  "quantity"
    t.index ["delivery_order_number"], name: "index_received_purchase_orders_on_delivery_order_number", unique: true, using: :btree
    t.index ["direct_purchase_id"], name: "index_received_purchase_orders_on_direct_purchase_id", using: :btree
    t.index ["purchase_order_id"], name: "index_received_purchase_orders_on_purchase_order_id", using: :btree
    t.index ["vendor_id"], name: "index_received_purchase_orders_on_vendor_id", using: :btree
  end

  create_table "recipients", force: :cascade do |t|
    t.integer  "notification_id"
    t.integer  "user_id"
    t.datetime "created_at",      precision: 6,                 null: false
    t.datetime "updated_at",      precision: 6,                 null: false
    t.boolean  "notified",                      default: false
    t.boolean  "read",                          default: false
    t.index ["notification_id"], name: "index_recipients_on_notification_id", using: :btree
    t.index ["user_id"], name: "index_recipients_on_user_id", using: :btree
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.string   "resource_type"
    t.integer  "resource_id"
    t.datetime "created_at",    precision: 6
    t.datetime "updated_at",    precision: 6
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  end

  create_table "sale_products", force: :cascade do |t|
    t.integer  "sale_id"
    t.integer  "product_barcode_id"
    t.integer  "quantity"
    t.decimal  "total"
    t.datetime "created_at",          precision: 6, null: false
    t.datetime "updated_at",          precision: 6, null: false
    t.integer  "event_id"
    t.integer  "free_product_id"
    t.integer  "price_list_id"
    t.integer  "returned_product_id"
    t.index ["event_id"], name: "index_sale_products_on_event_id", using: :btree
    t.index ["free_product_id"], name: "index_sale_products_on_free_product_id", using: :btree
    t.index ["price_list_id"], name: "index_sale_products_on_price_list_id", using: :btree
    t.index ["product_barcode_id"], name: "index_sale_products_on_product_barcode_id", using: :btree
    t.index ["returned_product_id"], name: "index_sale_products_on_returned_product_id", unique: true, using: :btree
    t.index ["sale_id"], name: "index_sale_products_on_sale_id", using: :btree
  end

  create_table "sales", force: :cascade do |t|
    t.integer  "member_id"
    t.datetime "transaction_time",      precision: 6
    t.integer  "bank_id"
    t.string   "payment_method"
    t.decimal  "total"
    t.string   "trace_number"
    t.string   "card_number"
    t.decimal  "cash"
    t.decimal  "change"
    t.string   "transaction_number"
    t.integer  "cashier_opening_id"
    t.datetime "created_at",            precision: 6, null: false
    t.datetime "updated_at",            precision: 6, null: false
    t.integer  "gift_event_id"
    t.integer  "gift_event_product_id"
    t.integer  "sales_return_id"
    t.index ["bank_id"], name: "index_sales_on_bank_id", using: :btree
    t.index ["cashier_opening_id"], name: "index_sales_on_cashier_opening_id", using: :btree
    t.index ["gift_event_id"], name: "index_sales_on_gift_event_id", using: :btree
    t.index ["gift_event_product_id"], name: "index_sales_on_gift_event_product_id", using: :btree
    t.index ["member_id"], name: "index_sales_on_member_id", using: :btree
    t.index ["sales_return_id"], name: "index_sales_on_sales_return_id", unique: true, using: :btree
    t.index ["transaction_number"], name: "index_sales_on_transaction_number", unique: true, using: :btree
  end

  create_table "sales_promotion_girls", force: :cascade do |t|
    t.string   "identifier"
    t.string   "name"
    t.text     "address"
    t.string   "phone"
    t.string   "province"
    t.integer  "warehouse_id"
    t.string   "mobile_phone"
    t.datetime "created_at",   precision: 6, null: false
    t.datetime "updated_at",   precision: 6, null: false
    t.string   "gender"
    t.string   "role"
    t.index ["identifier"], name: "index_sales_promotion_girls_on_identifier", unique: true, using: :btree
    t.index ["warehouse_id"], name: "index_sales_promotion_girls_on_warehouse_id", using: :btree
  end

  create_table "sales_return_products", force: :cascade do |t|
    t.integer  "sale_product_id"
    t.datetime "created_at",      precision: 6, null: false
    t.datetime "updated_at",      precision: 6, null: false
    t.integer  "sales_return_id"
    t.string   "reason"
    t.index ["sale_product_id", "sales_return_id"], name: "index_srp_on_sale_product_id_and_sales_return_id", unique: true, using: :btree
    t.index ["sales_return_id"], name: "index_sales_return_products_on_sales_return_id", using: :btree
  end

  create_table "sales_returns", force: :cascade do |t|
    t.integer  "sale_id"
    t.decimal  "total_return"
    t.integer  "total_return_quantity"
    t.string   "document_number"
    t.datetime "created_at",            precision: 6, null: false
    t.datetime "updated_at",            precision: 6, null: false
    t.index ["document_number"], name: "index_sales_returns_on_document_number", unique: true, using: :btree
    t.index ["sale_id"], name: "index_sales_returns_on_sale_id", unique: true, using: :btree
  end

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id",               null: false
    t.text     "data"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
    t.index ["updated_at"], name: "index_sessions_on_updated_at", using: :btree
  end

  create_table "shipment_product_items", force: :cascade do |t|
    t.integer  "order_booking_product_item_id"
    t.integer  "quantity"
    t.datetime "created_at",                    precision: 6, null: false
    t.datetime "updated_at",                    precision: 6, null: false
    t.integer  "shipment_product_id"
    t.index ["order_booking_product_item_id", "shipment_product_id"], name: "index_shipment_product_items_on_obpi_and_shipment_product_id", unique: true, using: :btree
    t.index ["shipment_product_id"], name: "index_shipment_product_items_on_shipment_product_id", using: :btree
  end

  create_table "shipment_products", force: :cascade do |t|
    t.integer  "order_booking_product_id"
    t.integer  "quantity"
    t.datetime "created_at",               precision: 6, null: false
    t.datetime "updated_at",               precision: 6, null: false
    t.integer  "shipment_id"
    t.index ["order_booking_product_id", "shipment_id"], name: "index_shipment_products_on_obp_id_and_shipment_id", unique: true, using: :btree
    t.index ["shipment_id"], name: "index_shipment_products_on_shipment_id", using: :btree
  end

  create_table "shipments", force: :cascade do |t|
    t.string   "delivery_order_number"
    t.date     "delivery_date"
    t.date     "received_date"
    t.integer  "order_booking_id"
    t.integer  "quantity"
    t.integer  "courier_id"
    t.datetime "created_at",              precision: 6,                 null: false
    t.datetime "updated_at",              precision: 6,                 null: false
    t.boolean  "is_receive_date_changed",               default: false
    t.boolean  "is_document_printed",                   default: false
    t.index ["courier_id"], name: "index_shipments_on_courier_id", using: :btree
    t.index ["delivery_order_number"], name: "index_shipments_on_delivery_order_number", unique: true, using: :btree
    t.index ["order_booking_id"], name: "index_shipments_on_order_booking_id", unique: true, using: :btree
  end

  create_table "size_groups", force: :cascade do |t|
    t.string   "code"
    t.text     "description"
    t.datetime "created_at",  precision: 6, null: false
    t.datetime "updated_at",  precision: 6, null: false
    t.index ["code"], name: "index_size_groups_on_code", unique: true, using: :btree
  end

  create_table "sizes", force: :cascade do |t|
    t.integer  "size_group_id"
    t.string   "size"
    t.datetime "created_at",    precision: 6, null: false
    t.datetime "updated_at",    precision: 6, null: false
    t.integer  "size_order"
    t.index ["size_group_id", "size"], name: "index_sizes_on_size_group_id_and_size", unique: true, using: :btree
  end

  create_table "stock_details", force: :cascade do |t|
    t.integer  "stock_product_id"
    t.integer  "size_id"
    t.integer  "color_id"
    t.integer  "quantity"
    t.datetime "created_at",          precision: 6,             null: false
    t.datetime "updated_at",          precision: 6,             null: false
    t.integer  "booked_quantity",                   default: 0
    t.integer  "unapproved_quantity",               default: 0
    t.index ["color_id"], name: "index_stock_details_on_color_id", using: :btree
    t.index ["size_id"], name: "index_stock_details_on_size_id", using: :btree
    t.index ["stock_product_id", "size_id", "color_id"], name: "index_stock_details_on_stock_product_id_size_id_color_id", unique: true, using: :btree
  end

  create_table "stock_movement_months", force: :cascade do |t|
    t.integer  "month"
    t.integer  "stock_movement_id"
    t.datetime "created_at",        precision: 6, null: false
    t.datetime "updated_at",        precision: 6, null: false
    t.index ["month", "stock_movement_id"], name: "index_stock_movement_months_on_month_and_stock_movement_id", unique: true, using: :btree
    t.index ["stock_movement_id"], name: "index_stock_movement_months_on_stock_movement_id", using: :btree
  end

  create_table "stock_movement_product_details", force: :cascade do |t|
    t.integer  "stock_movement_product_id"
    t.integer  "color_id"
    t.integer  "size_id"
    t.datetime "created_at",                precision: 6,             null: false
    t.datetime "updated_at",                precision: 6,             null: false
    t.integer  "beginning_stock",                         default: 0
    t.integer  "ending_stock",                            default: 0
    t.index ["color_id", "size_id"], name: "index_stock_movement_product_details_on_color_id_and_size_id", using: :btree
    t.index ["size_id"], name: "index_stock_movement_product_details_on_size_id", using: :btree
    t.index ["stock_movement_product_id", "color_id", "size_id"], name: "index_smpd_on_stock_movement_product_id_color_id_size_id", unique: true, using: :btree
  end

  create_table "stock_movement_products", force: :cascade do |t|
    t.integer  "product_id"
    t.integer  "stock_movement_warehouse_id"
    t.datetime "created_at",                  precision: 6, null: false
    t.datetime "updated_at",                  precision: 6, null: false
    t.index ["product_id", "stock_movement_warehouse_id"], name: "index_smp_on_product_id_and_stock_movement_warehouse_id", unique: true, using: :btree
    t.index ["stock_movement_warehouse_id"], name: "index_stock_movement_products_on_stock_movement_warehouse_id", using: :btree
  end

  create_table "stock_movement_transactions", force: :cascade do |t|
    t.integer  "stock_movement_product_detail_id"
    t.integer  "purchase_order_quantity_received",                default: 0
    t.integer  "delivery_order_quantity_received",                default: 0
    t.integer  "delivery_order_quantity_delivered",               default: 0
    t.integer  "stock_return_quantity_returned",                  default: 0
    t.integer  "stock_transfer_quantity_received",                default: 0
    t.integer  "stock_transfer_quantity_delivered",               default: 0
    t.integer  "stock_return_quantity_received",                  default: 0
    t.date     "transaction_date"
    t.datetime "created_at",                        precision: 6,             null: false
    t.datetime "updated_at",                        precision: 6,             null: false
    t.integer  "purchase_return_quantity_returned",               default: 0
    t.integer  "beginning_stock",                                 default: 0
    t.integer  "sold_quantity",                                   default: 0
    t.integer  "sales_return_quantity_received",                  default: 0
    t.integer  "consignment_sold_quantity",                       default: 0
    t.integer  "adjustment_in_quantity",                          default: 0
    t.index ["stock_movement_product_detail_id", "transaction_date"], name: "index_smt_on_stock_movement_product_detail_id_transaction_date", using: :btree
    t.index ["transaction_date"], name: "index_stock_movement_transactions_on_transaction_date", using: :btree
  end

  create_table "stock_movement_warehouses", force: :cascade do |t|
    t.integer  "stock_movement_month_id"
    t.integer  "warehouse_id"
    t.datetime "created_at",              precision: 6, null: false
    t.datetime "updated_at",              precision: 6, null: false
    t.index ["stock_movement_month_id", "warehouse_id"], name: "index_smw_on_stock_movement_month_id_and_warehouse_id", unique: true, using: :btree
    t.index ["warehouse_id"], name: "index_stock_movement_warehouses_on_warehouse_id", using: :btree
  end

  create_table "stock_movements", force: :cascade do |t|
    t.integer  "year"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["year"], name: "index_stock_movements_on_year", unique: true, using: :btree
  end

  create_table "stock_mutation_product_items", force: :cascade do |t|
    t.integer  "stock_mutation_product_id"
    t.integer  "size_id"
    t.integer  "color_id"
    t.integer  "quantity"
    t.datetime "created_at",                precision: 6, null: false
    t.datetime "updated_at",                precision: 6, null: false
    t.index ["color_id"], name: "index_stock_mutation_product_items_on_color_id", using: :btree
    t.index ["size_id"], name: "index_stock_mutation_product_items_on_size_id", using: :btree
    t.index ["stock_mutation_product_id", "size_id", "color_id"], name: "index_smpi_on_stock_mutation_product_id_size_id_color_id", unique: true, using: :btree
  end

  create_table "stock_mutation_products", force: :cascade do |t|
    t.integer  "stock_mutation_id"
    t.integer  "product_id"
    t.integer  "quantity"
    t.datetime "created_at",        precision: 6, null: false
    t.datetime "updated_at",        precision: 6, null: false
    t.index ["product_id"], name: "index_stock_mutation_products_on_product_id", using: :btree
    t.index ["stock_mutation_id", "product_id"], name: "index_stock_mutation_products_on_stock_mutation_product_id", unique: true, using: :btree
    t.index ["stock_mutation_id"], name: "index_stock_mutation_products_on_stock_mutation_id", using: :btree
  end

  create_table "stock_mutation_receipt_product_items", force: :cascade do |t|
    t.integer  "stock_mutation_receipt_product_id"
    t.integer  "stock_mutation_product_item_id"
    t.integer  "quantity"
    t.datetime "created_at",                        precision: 6, null: false
    t.datetime "updated_at",                        precision: 6, null: false
    t.index ["stock_mutation_product_item_id"], name: "index_smrpi_on_stock_mutation_product_item_id", using: :btree
    t.index ["stock_mutation_receipt_product_id", "stock_mutation_product_item_id"], name: "index_smrpi_on_smrp_id_and_smpi_id", unique: true, using: :btree
    t.index ["stock_mutation_receipt_product_id"], name: "index_smrpi_on_stock_mutation_receipt_product_id", using: :btree
  end

  create_table "stock_mutation_receipt_products", force: :cascade do |t|
    t.integer  "stock_mutation_receipt_id"
    t.integer  "stock_mutation_product_id"
    t.integer  "quantity"
    t.datetime "created_at",                precision: 6, null: false
    t.datetime "updated_at",                precision: 6, null: false
    t.index ["stock_mutation_product_id"], name: "index_smrp_on_stock_mutation_product_id", using: :btree
    t.index ["stock_mutation_receipt_id", "stock_mutation_product_id"], name: "index_smrp_on_smr_id_and_smp_id", unique: true, using: :btree
    t.index ["stock_mutation_receipt_id"], name: "index_smrp_on_stock_mutation_receipt_id", using: :btree
  end

  create_table "stock_mutation_receipts", force: :cascade do |t|
    t.integer  "quantity"
    t.integer  "stock_mutation_id"
    t.datetime "created_at",        precision: 6, null: false
    t.datetime "updated_at",        precision: 6, null: false
    t.index ["stock_mutation_id"], name: "index_stock_mutation_receipts_on_stock_mutation_id", unique: true, using: :btree
  end

  create_table "stock_mutations", force: :cascade do |t|
    t.date     "delivery_date"
    t.date     "received_date"
    t.integer  "quantity"
    t.integer  "origin_warehouse_id"
    t.string   "number"
    t.integer  "destination_warehouse_id"
    t.datetime "created_at",               precision: 6,                 null: false
    t.datetime "updated_at",               precision: 6,                 null: false
    t.date     "approved_date"
    t.boolean  "is_receive_date_changed",                default: false
    t.index ["destination_warehouse_id"], name: "index_stock_mutations_on_destination_warehouse_id", using: :btree
    t.index ["number"], name: "index_stock_mutations_on_number", unique: true, using: :btree
    t.index ["origin_warehouse_id"], name: "index_stock_mutations_on_origin_warehouse_id", using: :btree
  end

  create_table "stock_products", force: :cascade do |t|
    t.integer  "stock_id"
    t.integer  "product_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["product_id"], name: "index_stock_products_on_product_id", using: :btree
    t.index ["stock_id", "product_id"], name: "index_stock_products_on_stock_id_and_product_id", unique: true, using: :btree
  end

  create_table "stocks", force: :cascade do |t|
    t.datetime "created_at",   precision: 6, null: false
    t.datetime "updated_at",   precision: 6, null: false
    t.integer  "warehouse_id"
    t.index ["warehouse_id"], name: "index_stocks_on_warehouse_id", unique: true, using: :btree
  end

  create_table "supervisors", force: :cascade do |t|
    t.string   "code"
    t.string   "name"
    t.text     "address"
    t.string   "email"
    t.string   "phone"
    t.string   "mobile_phone"
    t.datetime "created_at",   precision: 6, null: false
    t.datetime "updated_at",   precision: 6, null: false
    t.index ["code"], name: "index_supervisors_on_code", unique: true, using: :btree
    t.index ["email"], name: "index_supervisors_on_email", unique: true, using: :btree
  end

  create_table "targets", force: :cascade do |t|
    t.integer  "warehouse_id"
    t.integer  "month"
    t.integer  "year"
    t.decimal  "target_value"
    t.datetime "created_at",   precision: 6, null: false
    t.datetime "updated_at",   precision: 6, null: false
    t.index ["warehouse_id", "month", "year"], name: "index_targets_on_warehouse_id_and_month_and_year", unique: true, using: :btree
    t.index ["warehouse_id"], name: "index_targets_on_warehouse_id", using: :btree
  end

  create_table "user_menus", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer  "ability"
    t.index ["user_id"], name: "index_user_menus_on_user_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                                 default: "", null: false
    t.string   "encrypted_password",                    default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at",  precision: 6
    t.datetime "remember_created_at",     precision: 6
    t.integer  "sign_in_count",                         default: 0,  null: false
    t.datetime "current_sign_in_at",      precision: 6
    t.datetime "last_sign_in_at",         precision: 6
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "sales_promotion_girl_id"
    t.datetime "created_at",              precision: 6,              null: false
    t.datetime "updated_at",              precision: 6,              null: false
    t.string   "name"
    t.string   "mobile_phone"
    t.string   "gender"
    t.string   "username"
    t.boolean  "active"
    t.string   "current_sign_in_token"
    t.string   "timezone_name"
    t.integer  "supervisor_id"
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    t.index ["sales_promotion_girl_id"], name: "index_users_on_sales_promotion_girl_id", using: :btree
    t.index ["supervisor_id"], name: "index_users_on_supervisor_id", unique: true, using: :btree
    t.index ["username"], name: "index_users_on_username", unique: true, using: :btree
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree
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
    t.datetime "created_at",              precision: 6, null: false
    t.datetime "updated_at",              precision: 6, null: false
    t.integer  "terms_of_payment"
    t.string   "value_added_tax"
    t.boolean  "is_taxable_entrepreneur"
    t.index ["code"], name: "index_vendors_on_code", unique: true, using: :btree
  end

  create_table "warehouses", force: :cascade do |t|
    t.string   "code"
    t.string   "name"
    t.text     "address"
    t.boolean  "is_active"
    t.integer  "supervisor_id"
    t.integer  "region_id"
    t.string   "warehouse_type"
    t.datetime "created_at",     precision: 6, null: false
    t.datetime "updated_at",     precision: 6, null: false
    t.integer  "price_code_id"
    t.string   "first_message"
    t.string   "second_message"
    t.string   "third_message"
    t.string   "fourth_message"
    t.string   "fifth_message"
    t.string   "sku"
    t.string   "counter_type"
    t.integer  "province_id"
    t.integer  "city_id"
    t.integer  "coa_id"
    t.index ["city_id"], name: "index_warehouses_on_city_id", using: :btree
    t.index ["code"], name: "index_warehouses_on_code", unique: true, using: :btree
    t.index ["price_code_id"], name: "index_warehouses_on_price_code_id", using: :btree
    t.index ["province_id"], name: "index_warehouses_on_province_id", using: :btree
    t.index ["region_id"], name: "index_warehouses_on_region_id", using: :btree
    t.index ["supervisor_id"], name: "index_warehouses_on_supervisor_id", using: :btree
  end

  add_foreign_key "adjustment_product_details", "adjustment_products"
  add_foreign_key "adjustment_product_details", "common_fields", column: "color_id"
  add_foreign_key "adjustment_product_details", "sizes"
  add_foreign_key "adjustment_products", "adjustments"
  add_foreign_key "adjustment_products", "products"
  add_foreign_key "adjustments", "warehouses"
  add_foreign_key "beginning_stock_products", "common_fields", column: "color_id"
  add_foreign_key "beginning_stock_products", "sizes"
  add_foreign_key "beginning_stock_products", "warehouses"
  add_foreign_key "coa_cashes", "coas"
  add_foreign_key "coas", "coa_types"
  add_foreign_key "courier_prices", "cities"
  add_foreign_key "courier_prices", "couriers"
  add_foreign_key "journal_detail_bogos", "journals"
  add_foreign_key "journal_detail_bogos", "products"
  add_foreign_key "journal_detail_gifts", "journals"
  add_foreign_key "journal_detail_gifts", "products"
  add_foreign_key "journal_detail_non_events", "journals"
  add_foreign_key "journal_detail_non_events", "products"
  add_foreign_key "journal_discount_details", "journals"
  add_foreign_key "journal_discount_details", "products"
  add_foreign_key "journals", "coas"
  add_foreign_key "order_bookings", "customers"
  add_foreign_key "targets", "warehouses"
  add_foreign_key "warehouses", "cities"
  add_foreign_key "warehouses", "provinces"
end
