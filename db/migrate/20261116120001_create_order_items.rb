class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: { on_delete: :restrict }
      t.string :product_code, null: false
      t.string :product_name_pt, null: false
      t.string :product_name_en, null: false
      t.string :stock_unit, null: false
      t.integer :unit_price_cents, null: false
      t.integer :quantity, null: false
      t.integer :stock_quantity_per_item, null: false
      t.integer :line_total_cents, null: false

      t.timestamps
    end

    add_index :order_items, %i[order_id product_id], unique: true
    add_check_constraint :order_items, "unit_price_cents >= 0", name: "order_items_price_nonnegative"
    add_check_constraint :order_items, "quantity > 0", name: "order_items_quantity_positive"
    add_check_constraint :order_items, "stock_quantity_per_item > 0", name: "order_items_stock_usage_positive"
    add_check_constraint :order_items, "line_total_cents >= 0", name: "order_items_total_nonnegative"
  end
end
