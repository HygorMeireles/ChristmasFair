class CostAllocation < ApplicationRecord
  belongs_to :order_item
  belongs_to :stock_batch

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :cost_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
