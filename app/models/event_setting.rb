class EventSetting < ApplicationRecord
  TEAM_NAME_FIELDS = %i[
    brownie_lead_name hot_chocolate_lead_name fishing_lead_name
    member_four_name member_five_name member_six_name
  ].freeze

  validates :mercado_pago_fee_basis_points, :debit_card_fee_basis_points, :credit_card_fee_basis_points,
    numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10_000 }
  validates(*TEAM_NAME_FIELDS, length: { maximum: 80 }, allow_blank: true)

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
