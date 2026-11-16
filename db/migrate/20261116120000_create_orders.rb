class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string :number, null: false
      t.string :checkout_token, null: false
      t.string :status, null: false
      t.string :payment_method, null: false
      t.integer :total_cents, null: false
      t.integer :amount_received_cents, null: false
      t.integer :change_cents, null: false
      t.datetime :paid_at, null: false

      t.timestamps
    end

    add_index :orders, :number, unique: true
    add_index :orders, :checkout_token, unique: true
    add_check_constraint :orders, "total_cents > 0", name: "orders_total_positive"
    add_check_constraint :orders, "amount_received_cents >= total_cents", name: "orders_received_covers_total"
    add_check_constraint :orders, "change_cents >= 0", name: "orders_change_nonnegative"
  end
end
