class AddPaymentFeesAndCancellation < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :provider_fee_cents, :integer, null: false, default: 0
    add_column :orders, :provider_fee_basis_points, :integer, null: false, default: 0
    add_check_constraint :orders, "provider_fee_cents >= 0", name: "orders_provider_fee_nonnegative"
    add_check_constraint :orders, "provider_fee_basis_points >= 0", name: "orders_provider_fee_rate_nonnegative"

    add_column :payment_attempts, :cancel_idempotency_key, :string
    add_index :payment_attempts, :cancel_idempotency_key, unique: true

    create_table :event_settings do |t|
      t.integer :mercado_pago_fee_basis_points, null: false, default: 100
      t.timestamps
    end
    add_check_constraint :event_settings,
      "mercado_pago_fee_basis_points BETWEEN 0 AND 10000",
      name: "event_settings_mercado_pago_fee_valid"
  end
end
