class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :code, null: false
      t.string :name_pt, null: false
      t.string :name_en, null: false
      t.integer :price_cents, null: false, default: 0
      t.string :stock_unit, null: false
      t.integer :stock_quantity, null: false, default: 0
      t.integer :capacity_quantity, null: false, default: 0
      t.integer :serving_size, null: false, default: 1
      t.boolean :active, null: false, default: true
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :products, :code, unique: true
    add_check_constraint :products, "price_cents >= 0", name: "products_price_nonnegative"
    add_check_constraint :products, "stock_quantity >= 0", name: "products_stock_nonnegative"
    add_check_constraint :products, "capacity_quantity >= 0", name: "products_capacity_nonnegative"
    add_check_constraint :products, "serving_size > 0", name: "products_serving_positive"
  end
end
