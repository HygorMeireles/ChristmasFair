class Expense < ApplicationRecord
  CATEGORIES = %w[ingredients packaging toys decoration other].freeze
  STATUSES = %w[pending paid].freeze

  validates :description, presence: true, length: { maximum: 120 }
  validates :category, inclusion: { in: CATEGORIES }
  validates :status, inclusion: { in: STATUSES }
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :incurred_on, presence: true
  validates :paid_on, presence: true, if: :paid?
  validates :notes, length: { maximum: 500 }

  scope :paid, -> { where(status: "paid") }
  scope :pending, -> { where(status: "pending") }
  scope :recent_first, -> { order(incurred_on: :desc, created_at: :desc) }

  def amount_brl
    format("%.2f", amount_cents.to_i / 100.0)
  end

  def amount_brl=(value)
    normalized = value.to_s.strip.gsub(/\s+/, "").tr(",", ".")
    self.amount_cents = (BigDecimal(normalized) * 100).round
  rescue ArgumentError
    self.amount_cents = nil
  end

  def paid?
    status == "paid"
  end
end
