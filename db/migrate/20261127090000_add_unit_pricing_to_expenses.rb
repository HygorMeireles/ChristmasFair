class AddUnitPricingToExpenses < ActiveRecord::Migration[8.0]
  def up
    add_column :expenses, :quantity, :integer, null: false, default: 1
    add_column :expenses, :unit_amount_cents, :integer
    add_column :expenses, :discount_cents, :integer, null: false, default: 0

    execute "UPDATE expenses SET unit_amount_cents = amount_cents"
    change_column_null :expenses, :unit_amount_cents, false

    add_check_constraint :expenses, "quantity > 0", name: "expenses_quantity_positive"
    add_check_constraint :expenses, "unit_amount_cents > 0", name: "expenses_unit_amount_positive"
    add_check_constraint :expenses, "discount_cents >= 0", name: "expenses_discount_nonnegative"
  end

  def down
    remove_check_constraint :expenses, name: "expenses_discount_nonnegative"
    remove_check_constraint :expenses, name: "expenses_unit_amount_positive"
    remove_check_constraint :expenses, name: "expenses_quantity_positive"
    remove_columns :expenses, :quantity, :unit_amount_cents, :discount_cents
  end
end
