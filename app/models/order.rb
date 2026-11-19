class Order < ApplicationRecord
  STATUSES = %w[pending paid cancelled refunded].freeze
  PAYMENT_METHODS = %w[cash pix card_debit card_credit].freeze

  has_many :order_items, dependent: :restrict_with_error
  has_many :payment_attempts, dependent: :restrict_with_error

  before_validation :assign_number, on: :create

  validates :number, :checkout_token, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }
  validates :total_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :amount_received_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :change_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :provider_fee_cents, :provider_fee_basis_points,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :paid_at, presence: true, if: :paid?
  validate :received_amount_covers_paid_order

  def paid?
    status == "paid"
  end

  def net_total_cents
    total_cents - provider_fee_cents
  end

  private

  def assign_number
    self.number ||= SecureRandom.alphanumeric(8).upcase
  end

  def received_amount_covers_paid_order
    return unless paid? && amount_received_cents.to_i < total_cents.to_i

    errors.add(:amount_received_cents, :greater_than_or_equal_to, count: total_cents)
  end
end
