class Order < ApplicationRecord
  STATUSES = %w[paid cancelled refunded].freeze
  PAYMENT_METHODS = %w[cash pix].freeze

  has_many :order_items, dependent: :restrict_with_error

  before_validation :assign_number, on: :create

  validates :number, :checkout_token, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }
  validates :total_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :amount_received_cents,
    numericality: { only_integer: true, greater_than_or_equal_to: :total_cents }
  validates :change_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :paid_at, presence: true

  private

  def assign_number
    self.number ||= SecureRandom.alphanumeric(8).upcase
  end
end
