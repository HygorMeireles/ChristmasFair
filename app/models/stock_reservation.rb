class StockReservation < ApplicationRecord
  STATUSES = %w[reserved confirmed released].freeze

  belongs_to :order_item
  belongs_to :product

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  validates :expires_at, presence: true

  scope :active, -> { where(status: "reserved") }
end
