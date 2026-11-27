class Expense < ApplicationRecord
  CATEGORIES = %w[ingredients packaging toys decoration other].freeze
  STATUSES = %w[pending paid].freeze

  validates :description, presence: true, length: { maximum: 120 }
  validates :category, inclusion: { in: CATEGORIES }
  validates :status, inclusion: { in: STATUSES }
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :discount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :incurred_on, presence: true
  validates :paid_on, presence: true, if: :paid?
  validates :notes, length: { maximum: 500 }

  scope :paid, -> { where(status: "paid") }
  scope :pending, -> { where(status: "pending") }
  scope :recent_first, -> { order(incurred_on: :desc, created_at: :desc) }

  has_one :stock_batch, dependent: :nullify

  before_validation :normalize_unit_pricing

  def amount_brl
    format("%.2f", amount_cents.to_i / 100.0)
  end

  def amount_brl=(value)
    normalized = value.to_s.strip.gsub(/\s+/, "").tr(",", ".")
    self.amount_cents = (BigDecimal(normalized) * 100).round
  rescue ArgumentError
    self.amount_cents = nil
  end

  def unit_amount_brl
    format("%.2f", unit_amount_cents.to_i / 100.0)
  end

  def unit_amount_brl=(value)
    self.unit_amount_cents = brl_to_cents(value)
  end

  def discount_brl
    format("%.2f", discount_cents.to_i / 100.0)
  end

  def discount_brl=(value)
    self.discount_cents = value.present? ? brl_to_cents(value) : 0
  end

  def paid?
    status == "paid"
  end

  private

  def normalize_unit_pricing
    self.quantity ||= 1
    self.discount_cents ||= 0
    self.unit_amount_cents ||= amount_cents if amount_cents.present? && quantity == 1
    return if unit_amount_cents.blank? || quantity.blank?

    self.amount_cents = (unit_amount_cents * quantity) - discount_cents
  end

  def brl_to_cents(value)
    normalized = value.to_s.strip.gsub(/\s+/, "").tr(",", ".")
    (BigDecimal(normalized) * 100).round
  rescue ArgumentError
    nil
  end
end
