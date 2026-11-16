# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_16_140001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "cost_allocations", force: :cascade do |t|
    t.bigint "order_item_id", null: false
    t.bigint "stock_batch_id", null: false
    t.integer "quantity", null: false
    t.integer "cost_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_item_id", "stock_batch_id"], name: "index_cost_allocations_on_order_item_id_and_stock_batch_id", unique: true
    t.index ["order_item_id"], name: "index_cost_allocations_on_order_item_id"
    t.index ["stock_batch_id"], name: "index_cost_allocations_on_stock_batch_id"
    t.check_constraint "cost_cents >= 0", name: "cost_allocations_cost_nonnegative"
    t.check_constraint "quantity > 0", name: "cost_allocations_quantity_positive"
  end

  create_table "expenses", force: :cascade do |t|
    t.string "description", null: false
    t.string "category", null: false
    t.integer "amount_cents", null: false
    t.date "incurred_on", null: false
    t.string "status", default: "pending", null: false
    t.date "paid_on"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_expenses_on_category"
    t.index ["incurred_on"], name: "index_expenses_on_incurred_on"
    t.index ["status"], name: "index_expenses_on_status"
    t.check_constraint "amount_cents > 0", name: "expenses_amount_positive"
  end

  create_table "fishing_tickets", force: :cascade do |t|
    t.bigint "order_item_id", null: false
    t.string "code", null: false
    t.string "status", default: "pending", null: false
    t.datetime "redeemed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_fishing_tickets_on_code", unique: true
    t.index ["order_item_id"], name: "index_fishing_tickets_on_order_item_id"
    t.index ["status"], name: "index_fishing_tickets_on_status"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.string "product_code", null: false
    t.string "product_name_pt", null: false
    t.string "product_name_en", null: false
    t.string "stock_unit", null: false
    t.integer "unit_price_cents", null: false
    t.integer "quantity", null: false
    t.integer "stock_quantity_per_item", null: false
    t.integer "line_total_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "cost_cents", default: 0, null: false
    t.boolean "cost_complete", default: false, null: false
    t.index ["order_id", "product_id"], name: "index_order_items_on_order_id_and_product_id", unique: true
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.check_constraint "cost_cents >= 0", name: "order_items_cost_nonnegative"
    t.check_constraint "line_total_cents >= 0", name: "order_items_total_nonnegative"
    t.check_constraint "quantity > 0", name: "order_items_quantity_positive"
    t.check_constraint "stock_quantity_per_item > 0", name: "order_items_stock_usage_positive"
    t.check_constraint "unit_price_cents >= 0", name: "order_items_price_nonnegative"
  end

  create_table "orders", force: :cascade do |t|
    t.string "number", null: false
    t.string "checkout_token", null: false
    t.string "status", null: false
    t.string "payment_method", null: false
    t.integer "total_cents", null: false
    t.integer "amount_received_cents", null: false
    t.integer "change_cents", null: false
    t.datetime "paid_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checkout_token"], name: "index_orders_on_checkout_token", unique: true
    t.index ["number"], name: "index_orders_on_number", unique: true
    t.check_constraint "amount_received_cents >= total_cents", name: "orders_received_covers_total"
    t.check_constraint "change_cents >= 0", name: "orders_change_nonnegative"
    t.check_constraint "total_cents > 0", name: "orders_total_positive"
  end

  create_table "products", force: :cascade do |t|
    t.string "code", null: false
    t.string "name_pt", null: false
    t.string "name_en", null: false
    t.integer "price_cents", default: 0, null: false
    t.string "stock_unit", null: false
    t.integer "stock_quantity", default: 0, null: false
    t.integer "capacity_quantity", default: 0, null: false
    t.integer "serving_size", default: 1, null: false
    t.boolean "active", default: true, null: false
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_products_on_code", unique: true
    t.check_constraint "capacity_quantity >= 0", name: "products_capacity_nonnegative"
    t.check_constraint "price_cents >= 0", name: "products_price_nonnegative"
    t.check_constraint "serving_size > 0", name: "products_serving_positive"
    t.check_constraint "stock_quantity >= 0", name: "products_stock_nonnegative"
  end

  create_table "stock_batches", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "expense_id"
    t.string "description", null: false
    t.integer "initial_quantity", null: false
    t.integer "remaining_quantity", null: false
    t.integer "total_cost_cents", null: false
    t.integer "allocated_cost_cents", default: 0, null: false
    t.date "received_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expense_id"], name: "index_stock_batches_on_expense_id"
    t.index ["product_id", "received_on"], name: "index_stock_batches_on_product_id_and_received_on"
    t.index ["product_id"], name: "index_stock_batches_on_product_id"
    t.check_constraint "allocated_cost_cents >= 0 AND allocated_cost_cents <= total_cost_cents", name: "stock_batches_allocated_cost_valid"
    t.check_constraint "initial_quantity > 0", name: "stock_batches_initial_positive"
    t.check_constraint "remaining_quantity >= 0 AND remaining_quantity <= initial_quantity", name: "stock_batches_remaining_valid"
    t.check_constraint "total_cost_cents > 0", name: "stock_batches_cost_positive"
  end

  create_table "stock_movements", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "movement_type", null: false
    t.integer "quantity_delta", null: false
    t.integer "stock_after", null: false
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_stock_movements_on_product_id"
    t.check_constraint "quantity_delta <> 0", name: "stock_movements_delta_nonzero"
    t.check_constraint "stock_after >= 0", name: "stock_movements_result_nonnegative"
  end

  add_foreign_key "cost_allocations", "order_items"
  add_foreign_key "cost_allocations", "stock_batches"
  add_foreign_key "fishing_tickets", "order_items"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products", on_delete: :restrict
  add_foreign_key "stock_batches", "expenses", on_delete: :nullify
  add_foreign_key "stock_batches", "products"
  add_foreign_key "stock_movements", "products"
end
