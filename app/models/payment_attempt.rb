class PaymentAttempt < ApplicationRecord
  STATUSES = %w[creating pending unknown approved failed cancelled expired].freeze

  belongs_to :order

  validates :public_token, :idempotency_key, presence: true, uniqueness: true
  validates :provider, inclusion: { in: %w[mercado_pago] }
  validates :status, inclusion: { in: STATUSES }
  validates :external_order_id, uniqueness: true, allow_nil: true

  scope :open, -> { where(status: %w[creating pending unknown]) }

  def pending?
    status.in?(%w[creating pending unknown])
  end

  def approved?
    status == "approved"
  end
end
