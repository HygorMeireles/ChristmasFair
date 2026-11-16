class CreateStockMovements < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_movements do |t|
      t.references :product, null: false, foreign_key: true
      t.string :movement_type, null: false
      t.integer :quantity_delta, null: false
      t.integer :stock_after, null: false
      t.string :note

      t.timestamps
    end


    add_check_constraint :stock_movements, "quantity_delta <> 0", name: "stock_movements_delta_nonzero"
    add_check_constraint :stock_movements, "stock_after >= 0", name: "stock_movements_result_nonnegative"
  end
end
