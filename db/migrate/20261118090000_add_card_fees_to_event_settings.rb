class AddCardFeesToEventSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :event_settings, :debit_card_fee_basis_points, :integer, null: false, default: 89
    add_column :event_settings, :credit_card_fee_basis_points, :integer, null: false, default: 309

    add_check_constraint :event_settings,
      "debit_card_fee_basis_points BETWEEN 0 AND 10000",
      name: "event_settings_debit_card_fee_valid"
    add_check_constraint :event_settings,
      "credit_card_fee_basis_points BETWEEN 0 AND 10000",
      name: "event_settings_credit_card_fee_valid"
  end
end
