class FishingTicket < ApplicationRecord
  STATUSES = %w[pending redeemed].freeze

  belongs_to :order_item
  has_one :order, through: :order_item

  before_validation :assign_code, on: :create

  validates :code, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :redeemed_at, presence: true, if: :redeemed?

  scope :recent_first, -> { order(created_at: :desc) }

  def pending?
    status == "pending"
  end

  def redeemed?
    status == "redeemed"
  end

  private

  def assign_code
    self.code ||= "PESCA-#{SecureRandom.alphanumeric(10).upcase}"
  end
end
