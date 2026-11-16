class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.string :description, null: false
      t.string :category, null: false
      t.integer :amount_cents, null: false
      t.date :incurred_on, null: false
      t.string :status, null: false, default: "pending"
      t.date :paid_on
      t.text :notes

      t.timestamps
    end

    add_index :expenses, :category
    add_index :expenses, :status
    add_index :expenses, :incurred_on
    add_check_constraint :expenses, "amount_cents > 0", name: "expenses_amount_positive"
  end
end
