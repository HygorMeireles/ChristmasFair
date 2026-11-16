class CreateFishingTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :fishing_tickets do |t|
      t.references :order_item, null: false, foreign_key: true
      t.string :code, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :redeemed_at

      t.timestamps
    end

    add_index :fishing_tickets, :code, unique: true
    add_index :fishing_tickets, :status
  end
end
