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

ActiveRecord::Schema[8.1].define(version: 2026_11_16_044425) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  add_foreign_key "stock_movements", "products"
end
