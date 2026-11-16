class CreateCostAllocations < ActiveRecord::Migration[8.1]
  def change
    add_column :order_items, :cost_cents, :integer, null: false, default: 0
    add_column :order_items, :cost_complete, :boolean, null: false, default: false
    add_check_constraint :order_items, "cost_cents >= 0", name: "order_items_cost_nonnegative"

    create_table :cost_allocations do |t|
      t.references :order_item, null: false, foreign_key: true
      t.references :stock_batch, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.integer :cost_cents, null: false

      t.timestamps
    end

    add_index :cost_allocations, %i[order_item_id stock_batch_id], unique: true
    add_check_constraint :cost_allocations, "quantity > 0", name: "cost_allocations_quantity_positive"
    add_check_constraint :cost_allocations, "cost_cents >= 0", name: "cost_allocations_cost_nonnegative"
  end
end
