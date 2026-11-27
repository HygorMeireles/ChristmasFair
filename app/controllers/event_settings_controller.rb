class EventSettingsController < ApplicationController
  def update
    setting = EventSetting.current
    if setting.update(setting_params)
      redirect_to products_path, notice: t("event_settings.updated")
    else
      redirect_to products_path, alert: setting.errors.full_messages.to_sentence
    end
  end

  private

  def setting_params
    params.require(:event_setting).permit(
      :mercado_pago_fee_percent,
      :debit_card_fee_percent,
      :credit_card_fee_percent,
      *EventSetting::TEAM_NAME_FIELDS
    )
  end
end
