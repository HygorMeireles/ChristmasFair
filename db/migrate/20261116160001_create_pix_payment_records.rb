class CreatePixPaymentRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_attempts do |t|
      t.references :order, null: false, foreign_key: true
      t.string :public_token, null: false
      t.string :provider, null: false, default: "mercado_pago"
      t.string :status, null: false, default: "creating"
      t.string :idempotency_key, null: false
      t.string :external_order_id
      t.string :external_payment_id
      t.text :qr_data
      t.datetime :expires_at
      t.jsonb :raw_response, null: false, default: {}
      t.text :error_message

      t.timestamps
    end

    add_index :payment_attempts, :public_token, unique: true
    add_index :payment_attempts, :idempotency_key, unique: true
    add_index :payment_attempts, :external_order_id, unique: true
    add_index :payment_attempts, :status

    create_table :stock_reservations do |t|
      t.references :order_item, null: false, foreign_key: true, index: { unique: true }
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.string :status, null: false, default: "reserved"
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :stock_reservations, %i[product_id status]
    add_check_constraint :stock_reservations, "quantity > 0", name: "stock_reservations_quantity_positive"

    create_table :payment_events do |t|
      t.string :event_key, null: false
      t.string :resource_id, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :processed_at
      t.text :error_message

      t.timestamps
    end

    add_index :payment_events, :event_key, unique: true
    add_index :payment_events, :resource_id
  end
end
