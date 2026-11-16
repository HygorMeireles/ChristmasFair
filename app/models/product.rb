class Product < ApplicationRecord
  CODES = %w[brownie hot_chocolate fishing].freeze
  STOCK_UNITS = %w[unit ml].freeze

  has_many :stock_movements, dependent: :restrict_with_error
  has_many :stock_batches, dependent: :restrict_with_error
  has_many :order_items, dependent: :restrict_with_error

  validates :code, inclusion: { in: CODES }, uniqueness: true
  validates :name_pt, :name_en, presence: true
  validates :price_cents, :stock_quantity, :capacity_quantity,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :serving_size, numericality: { only_integer: true, greater_than: 0 }
  validates :stock_unit, inclusion: { in: STOCK_UNITS }
  validate :stock_does_not_exceed_capacity

  scope :active, -> { where(active: true) }
  scope :display_order, -> { order(Arel.sql("CASE code WHEN 'brownie' THEN 1 WHEN 'hot_chocolate' THEN 2 ELSE 3 END")) }

  def localized_name(locale = I18n.locale)
    locale.to_s == "en" ? name_en : name_pt
  end

  def price_brl
    format("%.2f", price_cents.to_i / 100.0)
  end

  def price_brl=(value)
    normalized = value.to_s.strip.tr(",", ".")
    self.price_cents = (BigDecimal(normalized) * 100).round if normalized.present?
  rescue ArgumentError
    self.price_cents = nil
  end

  def available_servings
    stock_quantity / serving_size
  end

  def stock_percentage
    return 0 if capacity_quantity.zero?

    ((stock_quantity.to_f / capacity_quantity) * 100).clamp(0, 100).round(1)
  end

  def hot_chocolate?
    code == "hot_chocolate"
  end

  private

  def stock_does_not_exceed_capacity
    return unless hot_chocolate? && capacity_quantity.present? && stock_quantity.present?
    return if capacity_quantity.zero? || stock_quantity <= capacity_quantity

    errors.add(:stock_quantity, :less_than_or_equal_to, count: capacity_quantity)
  end
end
