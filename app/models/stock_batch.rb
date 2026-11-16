class StockBatch < ApplicationRecord
  belongs_to :product
  belongs_to :expense, optional: true
  has_many :cost_allocations, dependent: :restrict_with_error

  validates :description, presence: true, length: { maximum: 120 }
  validates :initial_quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :remaining_quantity,
    numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: :initial_quantity }
  validates :total_cost_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :allocated_cost_cents,
    numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: :total_cost_cents }
  validates :received_on, presence: true

  scope :available, -> { where("remaining_quantity > 0") }
  scope :fifo, -> { order(:received_on, :id) }

  def unit_cost_cents
    total_cost_cents.to_d / initial_quantity
  end
end
