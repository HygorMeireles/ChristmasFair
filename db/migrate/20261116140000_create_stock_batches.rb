class CreateStockBatches < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_batches do |t|
      t.references :product, null: false, foreign_key: true
      t.references :expense, null: true, foreign_key: { on_delete: :nullify }
      t.string :description, null: false
      t.integer :initial_quantity, null: false
      t.integer :remaining_quantity, null: false
      t.integer :total_cost_cents, null: false
      t.integer :allocated_cost_cents, null: false, default: 0
      t.date :received_on, null: false

      t.timestamps
    end

    add_index :stock_batches, %i[product_id received_on]
    add_check_constraint :stock_batches, "initial_quantity > 0", name: "stock_batches_initial_positive"
    add_check_constraint :stock_batches, "remaining_quantity >= 0 AND remaining_quantity <= initial_quantity", name: "stock_batches_remaining_valid"
    add_check_constraint :stock_batches, "total_cost_cents > 0", name: "stock_batches_cost_positive"
    add_check_constraint :stock_batches, "allocated_cost_cents >= 0 AND allocated_cost_cents <= total_cost_cents", name: "stock_batches_allocated_cost_valid"
  end
end
