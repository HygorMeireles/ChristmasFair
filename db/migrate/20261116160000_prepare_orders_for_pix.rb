class PrepareOrdersForPix < ActiveRecord::Migration[8.1]
  def change
    change_column_null :orders, :paid_at, true
    change_column_default :orders, :amount_received_cents, from: nil, to: 0
    change_column_default :orders, :change_cents, from: nil, to: 0
    remove_check_constraint :orders, name: "orders_received_covers_total"
    add_check_constraint :orders,
      "status <> 'paid' OR amount_received_cents >= total_cents",
      name: "orders_paid_amount_covers_total"
  end
end
