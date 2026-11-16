class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
  has_many :fishing_tickets, dependent: :restrict_with_error
  has_many :cost_allocations, dependent: :restrict_with_error
  has_many :stock_batches, through: :cost_allocations

  validates :product_code, :product_name_pt, :product_name_en, :stock_unit, presence: true
  validates :unit_price_cents, :line_total_cents,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :quantity, :stock_quantity_per_item,
    numericality: { only_integer: true, greater_than: 0 }
end
