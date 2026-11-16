class StockMovement < ApplicationRecord
  TYPES = %w[initial restock loss correction sale].freeze

  belongs_to :product

  validates :movement_type, inclusion: { in: TYPES }
  validates :quantity_delta, numericality: { only_integer: true, other_than: 0 }
  validates :stock_after, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
