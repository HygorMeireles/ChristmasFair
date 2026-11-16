class Webhooks::MercadoPagoController < ApplicationController
  skip_forgery_protection
  before_action :verify_signature!

  def create
    resource_id = params.dig(:data, :id).to_s
    return head :ok unless params[:type] == "order" && resource_id.present?

    event = PaymentEvent.create_or_find_by!(event_key: event_key) do |record|
      record.resource_id = resource_id
      record.payload = request.request_parameters
    end
    ProcessMercadoPagoOrderJob.perform_later(resource_id, event.id) unless event.processed_at?
    head :ok
  end

  private

  def verify_signature!
    signature = request.headers["x-signature"].to_s
    request_id = request.headers["x-request-id"].to_s
    data_id = params.dig(:data, :id).to_s
    timestamp = signature[/ts=(\d+)/, 1]
    provided = signature[/v1=([a-f0-9]+)/, 1]
    secret = webhook_secret

    return head :unauthorized if [ request_id, data_id, timestamp, provided, secret ].any?(&:blank?)

    epoch = timestamp.to_i
    epoch /= 1000 if epoch > 10_000_000_000
    return head :unauthorized unless Time.at(epoch).between?(10.minutes.ago, 10.minutes.from_now)

    manifest = "id:#{data_id};request-id:#{request_id};ts:#{timestamp};"
    expected = OpenSSL::HMAC.hexdigest("SHA256", secret, manifest)
    head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(expected, provided)
  end

  def webhook_secret
    ENV["MERCADO_PAGO_WEBHOOK_SECRET"].presence || Rails.application.credentials.dig(:mercado_pago, :webhook_secret)
  end

  def event_key
    "#{params[:id]}:#{params[:action]}:#{params.dig(:data, :id)}"
  end
end
