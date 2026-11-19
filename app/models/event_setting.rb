class EventSetting < ApplicationRecord
  validates :mercado_pago_fee_basis_points, :debit_card_fee_basis_points, :credit_card_fee_basis_points,
    numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10_000 }

  def self.current
    first_or_create!(mercado_pago_fee_basis_points: 100)
  end

  def mercado_pago_fee_percent
    format("%.2f", mercado_pago_fee_basis_points.to_i / 100.0)
  end

  def mercado_pago_fee_percent=(value)
    normalized = value.to_s.strip.tr(",", ".")
    self.mercado_pago_fee_basis_points = (BigDecimal(normalized) * 100).round if normalized.present?
  rescue ArgumentError
    self.mercado_pago_fee_basis_points = nil
  end

  def debit_card_fee_percent
    format("%.2f", debit_card_fee_basis_points.to_i / 100.0)
  end

  def debit_card_fee_percent=(value)
    self.debit_card_fee_basis_points = percent_to_basis_points(value)
  end

  def credit_card_fee_percent
    format("%.2f", credit_card_fee_basis_points.to_i / 100.0)
  end

  def credit_card_fee_percent=(value)
    self.credit_card_fee_basis_points = percent_to_basis_points(value)
  end

  private

  def percent_to_basis_points(value)
    normalized = value.to_s.strip.tr(",", ".")
    return if normalized.blank?

    (BigDecimal(normalized) * 100).round
  rescue ArgumentError
    nil
  end
end
